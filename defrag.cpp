#include <string>
#include <iostream>
#include <vector>
#include <unistd.h>

#include "hip/hip_runtime.h"

#define HIPCHECK(stmt) do {                                             \
    hipError_t err = stmt;                                              \
    if (err != hipSuccess) {                                            \
      char msg[256];                                                    \
      sprintf(msg, "%s in file %s, function %s, line %d\n", #stmt,__FILE__,__FUNCTION__,__LINE__); \
      std::string errstring = hipGetErrorString(err);                   \
      std::cerr << msg << "\t" << errstring << std::endl;               \
      exit(1);                                                          \
    }                                                                   \
  } while(0)

#define MY_MAXHOSTNAMELEN 255

int main()
{
  int n_devices;
  char hostname[MY_MAXHOSTNAMELEN+1] = { 0 };
  if (gethostname(hostname, MY_MAXHOSTNAMELEN) == 0) {
    hostname[MY_MAXHOSTNAMELEN] = '\0';
  } else hostname[0] = '\0';
  HIPCHECK(hipGetDeviceCount(&n_devices));

  size_t min_free = SIZE_MAX;
  for (int d = 0; d < n_devices; d++) {
    size_t free, total;
    HIPCHECK(hipSetDevice(d));
    HIPCHECK(hipMemGetInfo(&free,&total));
    if (free < min_free) min_free = free;
  }

  const size_t oneGiB = size_t(1024*1024*1024);
  size_t thresh = min_free - (8 * oneGiB);
  size_t memsize = 116 * oneGiB;
  if (memsize > thresh) memsize = thresh;

  std::cout << hostname << ": hipMalloc(" << memsize << ") bytes each on " << n_devices << " devices\n";
  std::vector<double *> data(4,nullptr);
  for (int d = 0; d < n_devices; d++) {
    HIPCHECK(hipSetDevice(d));
    HIPCHECK(hipMalloc(&(data[d]),memsize));
  }

  for (int d = 0; d < n_devices; d++) HIPCHECK(hipFree(data[d]));

  std::cout << hostname << ": memory defragging done!" << std::endl;

  return 0;
}

