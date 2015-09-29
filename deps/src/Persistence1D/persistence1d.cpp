#include "persistence1d.hpp"
#include <cstddef>
#include <vector>
#include <algorithm>

extern "C" {
  void find_extrema(const float* v, std::size_t n,
                    int** minIndices, std::size_t* nmin,
                    int** maxIndices, std::size_t* nmax,
                    const float threshold = 0);
}

void find_extrema(const float* v, std::size_t n,
                  int** minIndices, std::size_t* nmin,
                  int** maxIndices, std::size_t* nmax,
                  const float threshold)
{
  p1d::Persistence1D p;
  std::vector<float> vv(n);
  std::copy(v, v+n, std::begin(vv));
  if(p.RunPersistence(vv)){
    std::vector<int> min_v, max_v;
    p.GetExtremaIndices(min_v, max_v, threshold, true);
    min_v.push_back(p.GetGlobalMinimumIndex(true));
    *nmin = min_v.size();
    *nmax = max_v.size();
    *minIndices = new int[*nmin];
    *maxIndices = new int[*nmax];
    std::copy(std::begin(min_v), std::end(min_v), *minIndices);
    std::copy(std::begin(max_v), std::end(max_v), *maxIndices);
  }
}
