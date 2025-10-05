#include <string>
#include <iostream>
#include <vector>
#include <limits>
#include <cstdio>
#include <cstdlib>
#include <unistd.h>
#include "hip/hip_runtime.h"

//
// This program uses AMD's HIP API to "defragment" GPU memory 
// across all available devices. It identifies the minimum free 
// memory on any device, allocates a large contiguous block 
// (up to 116 GiB, capped at available free minus 8 GiB) on each GPU, 
// immediately frees it, and logs the hostname and completion status. 
//
// joe gonzalez, MSL, June 2025 
//


#define HIPCHECK(stmt) do {                                             \
    hipError_t err = stmt;                                              \
    if (err != hipSuccess) {                                            \
      char msg[256];                                                    \
      sprintf(msg, "%s in file %s, function %s, line %d\n", #stmt, __FILE__, __FUNCTION__, __LINE__); \
      std::string errstring = hipGetErrorString(err);                   \
      std::cerr << msg << "\t" << errstring << std::endl;               \
      exit(1);                                                          \
    }                                                                   \
  } while(0)

constexpr size_t MY_MAXHOSTNAMELEN = 255;
constexpr size_t ONE_GIB = 1024ULL * 1024ULL * 1024ULL;
constexpr size_t TARGET_ALLOCATION = 116 * ONE_GIB;
constexpr size_t SAFETY_MARGIN = 8 * ONE_GIB;

int main() {
  int n_devices = 0;
  std::string hostname;
  char hostname_buf[MY_MAXHOSTNAMELEN + 1] = {0};
  if (gethostname(hostname_buf, MY_MAXHOSTNAMELEN) == 0) {
    hostname = hostname_buf;
  } else {
    hostname = "unknown";
  }

  HIPCHECK(hipGetDeviceCount(&n_devices));
  if (n_devices == 0) {
    std::cerr << "No HIP devices found." << std::endl;
    return 1;
  }

  size_t min_free = std::numeric_limits<size_t>::max();
  for (int d = 0; d < n_devices; ++d) {
    size_t free_mem, total_mem;
    HIPCHECK(hipSetDevice(d));
    HIPCHECK(hipMemGetInfo(&free_mem, &total_mem));
    if (free_mem < min_free) {
      min_free = free_mem;
    }
  }

  // Ensure we don't allocate more than available after safety margin
  size_t available = (min_free > SAFETY_MARGIN) ? (min_free - SAFETY_MARGIN) : 0;
  size_t memsize = (TARGET_ALLOCATION > available) ? available : TARGET_ALLOCATION;

  std::cout << hostname << ":: hipMalloc() Allocating ~" << memsize / ONE_GIB << " GB on each of " << n_devices << " devices...\n";

  // Size vector to match number of devices (fix: was hardcoded to 4)
  std::vector<void*> data(n_devices, nullptr);  // Use void* for raw memory allocation
  for (int d = 0; d < n_devices; ++d) {
    HIPCHECK(hipSetDevice(d));
    if (memsize > 0) {
      HIPCHECK(hipMalloc(&data[d], memsize));
    }
  }

  // Free in reverse order for better defrag potential
  for (int d = n_devices - 1; d >= 0; --d) {
    if (data[d] != nullptr) {
      HIPCHECK(hipSetDevice(d));
      HIPCHECK(hipFree(data[d]));
      data[d] = nullptr;
    }
  }

  std::cout << hostname << ": memory defragging done!" << std::endl;
  return 0;
}


