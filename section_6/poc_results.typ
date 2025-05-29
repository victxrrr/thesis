When compiling OpenMP with GPU offloading, we received warnings about copying non-trivially copyable data to GPU memory, meaning the mapping was not guaranteed to be correct. Our C++ program uses custom classes for mesh cells and interfaces, which have custom constructors, making them non-trivially copyable. This is a fundamental aspect of the current Watlab architecture that we cannot bypass for now. When executing the binary, it crashed inexplicably, likely due to incorrect memory mapping. As a result, the OpenMP solution has been dropped and will no longer appear in the following results.

Furthermore, implementing the PoC with RAJA revealed its backend-dependent API. Many constants and functions are prefixed with `cuda`/`hip`/`omp`/... requiring code duplication and macros to manage hardware-specific compilation. This makes the code impractical and insufficiently abstracted compared to other libraries. Consequently, RAJA will not be discussed further.

Abstraction libraries such as Kokkos, Alpaka, and SYCL allow writing code that is easily understandable for developers with no prior GPU programming knowledge. Their abstraction paradigms differ significantly from one framework to another. Alpaka mainly relies on compile time templates with a syntax relatively close to CUDA by keeping separate kernel definitions. In contrast, Kokkos offers a higher level of abstraction by encapsulating data into `View` objects and by providing `parallel_for` constructs that easily offload loop processing to the GPU. The approach followed by the SYCL standard is quite singular and is based on events and queues. Jobs are submitted to a queue and executed on the GPU, either in-order or out-of-order depending on the configuration. An illustrative example of Kokkos and SYCL pseudocode compared to CUDA implementation is given below.

```cpp
                          /* Transfer data host -> device */
// CUDA
cudaMalloc((void **) &d_cells, N * sizeof(Cell));
cudaMemcpy(d_cells, h_cells, N * sizeof(Cell), cudaMemcpyHostToDevice);
// Kokkos
Kokkos::View<Cell*, Kokkos::HostSpace> h_cells(data, N);
Kokkos::View<Cell*> d_cells("cells", N);
Kokkos::deep_copy(d_cells, h_cells);
// SYCL
sycl::queue q(sycl::default_selector{}, sycl::property::queue::in_order{});
Cell* d_cells = sycl::malloc_device<Cell>(N, q);
q.memcpy(d_cells, h_cells, N * sizeof(Cell));

                                  /* Kernel launch */
// CUDA
__global__ void updateKernel(Cell* d_cells, int N)
{
    int i = blockIdx.x * blockDim.x + threadIdx.x;
    if (i < N)
    {
        d_cells[i].h += 2e-6;
    }
}
int threadsPerBlock = 128
int blocksPerGrid = (N + threadsPerBlock - 1) / threadsPerBlock;
updateKernel<<<blocksPerGrid, threadsPerBlock>>>(d_cells, N);
cudaDeviceSynchronize();
// Kokkos
Kokkos::parallel_for("UpdateKernel", d_cells.extent(0), KOKKOS_LAMBDA(const int i){
    d_theCells(i).h += 2e-6;
});
// SYCL
q.submit([&](sycl::handler &h) {
    h.parallel_for<class UpdateKernel>(sycl::range<1>(N), [=](sycl::id<1> i) {
        d_cells[i].h += 2e-6;
    });
});
```
Another interesting feature of abstraction libraries shown by the above pseudocode is the automatic assignment of the number of threads per block, which is done by querying the hardware and using occupancy heuristics. This makes the choice robust across different devices and enhances portability.

As in the Watlab implementation, the PoC includes a minimum reduction to compute the minimum water height in the domain. The need for an efficient parallel reduction algorithm is even more critical than in the CPU implementation given the high number of threads that must communicate. Furthermore, due to the high latency of global memory, intrablock communication should be preferred through shared memory when possible. To achieve a backend independent parallel implementation that meets this requirement, we rely on built in optimized algorithms provided by the libraries, which handle technical details and ease the programmer's work. This choice aligns with the PoC objectives stated at the beginning of the section.

For this reason, Alpaka remains less attractive as it does not provide such reductions, unlike CUDA, Kokkos, or AdaptiveCpp. To effectively compare the remaining candidates, we considered the following test case. We used the Toce _XL_ geometry as input to create sufficient computational load so that the benefits of GPU offloading could be clearly observed. Water heights were initialized with pseudorandom values between 0 and 1 according to a user defined seed. The rest of the execution follows the chart shown in @poc and we simulated $T=1000$ steps. Only the execution of this part was recorded.
//No measurements were performed for Alpaka as this would lead to unfair comparisons since the reduction kernel is skipped and could confuse the reader.
The measurements for the different implementations are listed in @poc_times.
Execution times are measured over 100 runs, discarding the first ten to avoid warm up effects.

#show table.cell.where(y: 0): strong
#set table(
  stroke: (x, y) => if y == 0 {
    (bottom: 0.7pt + black)
  },
  align: (x, y) => (
    if x > 0 { center }
    else { left }
  )
)

#import "@preview/fancy-units:0.1.1": unit, qty

#figure(table(
  columns: (1fr, 1fr, 1fr),
  table.header(
    [Framework],
    [Duration [#unit[s]]],
    [$"Speedup"_"serial"$],
  ),
  [Serial], [$56.18 thick (plus.minus 0.29)$], [1],
  [OpenMP (20 threads)], [$3.31 thick (plus.minus 0.19)$], [16.95],
  [CUDA], [$2.13 thick (plus.minus 0.01)$], [26.41],
  [Kokkos], [$2.10 thick (plus.minus 0.02)$], [26.81],
  [AdaptiveCpp], [$2.32 thick (plus.minus 0.04)$], [24.22]
), caption: [Timings of the PoC on Toce _XL_ over 1000 steps])
<poc_times>

We observe that the speedups achieved with the GPU implementations are significant and greater than those of the OpenMP parallel version. The results are quite similar among the GPU implementations. We would also expect the CUDA implementation to yield the lowest mean execution times as it does not introduce abstraction overhead.
The slightly larger execution time of the AdaptiveCpp implementation mainly results from the initialization of the queue.
The point is that, as CPU and GPU are different hardware that execute independently, CPU based timings like those presented may not be accurate given the asynchronous nature of the program.
A more reliable way to compare them is to use GPU specific profiling tools such as NVIDIA Nsight Compute, which is part of the CUDA toolkit and allows to perform kernel profiling. The results are shown in @ncu.

#import "@preview/subpar:0.2.2"

#subpar.grid(
  figure(table(
      columns: (1fr,1fr,1fr,1fr),
      table.header(
        [Framework],
        [Duration #unit[[ms]]],
        [Compute \ Throughput #unit[[%]]],
        [Memory \ Throughput #unit[[%]]],
      ),
      [CUDA], [$1.38 thick (plus.minus 0.004)$], [$2.8 thick (plus.minus 0.009)$], [$47.758 thick (plus.minus 0.123)$],
      [Kokkos], [$1.384 thick (plus.minus 0.005)$], [$2.796 thick (plus.minus 0.008)$], [$47.596 thick (plus.minus 0.140)$],
      [AdaptiveCpp], [$1.38 thick (plus.minus 0.005)$], [$2.799 thick (plus.minus 0.009)$], [$47.757 thick (plus.minus 0.140)$],
    ), gap: .75em, caption: [Flux kernel]),
  figure(table(
    columns: (1fr,1fr,1fr,1fr),
    table.header(
      [Framework],
      [Duration #unit[[ms]]],
      [Compute \ Throughput #unit[[%]]],
      [Memory \ Throughput #unit[[%]]],
    ),
    [CUDA], [$0.29 thick (plus.minus 0.004)$], [$4.522 thick (plus.minus 0.058)$], [$86.744 thick (plus.minus 0.408)$],
    [Kokkos], [$0.293 thick (plus.minus 0.005)$], [$4.46 thick (plus.minus 0.029)$], [$85.448 thick (plus.minus 0.466)$],
    [AdaptiveCpp], [$0.291 thick (plus.minus 0.004)$], [$4.515 thick (plus.minus 0.058)$], [$86.578 thick (plus.minus 0.516)$],
  ), gap: .75em, caption: [Update kernel]),
  figure(table(
    columns: (1fr,1fr,1fr,1fr),
    table.header(
      [Framework],
      [Duration #unit[[ms]]],
      [Compute \ Throughput #unit[[%]]],
      [Memory \ Throughput #unit[[%]]],
    ),
    [CUDA], [$0.15 thick (plus.minus 0.000)$], [$14.18 thick (plus.minus 0.067)$], [$97.57 thick (plus.minus 0.364)$],
    [Kokkos], [$0.151 thick (plus.minus 0.003)$], [$12.434 thick (plus.minus 0.044)$], [$91.054 thick (plus.minus 0.290)$],
    [AdaptiveCpp], [$0.15 thick (plus.minus 0.000)$], [$9.42 thick (plus.minus 0.022)$], [$95.30 thick (plus.minus 0.171)$],
  ), gap: .75em, caption: [Min reduction]),
  columns: 1,
  caption: [Per-kernel profiling],
  kind: table,
  label: <ncu>,
  numbering: n => numbering("1.1", ..counter(heading.where(level: 1)).get(), n),
  numbering-sub-ref: (..n) => {
    numbering("1.1a", ..counter(heading.where(level: 1)).get(), ..n)
  },
  gap: 1em
)
This analysis shows that abstraction libraries are competitive with naive CUDA code while offering simplicity and portability. Furthermore, the low compute throughput shows that this PoC is an example of a memory bound algorithm. Between the two libraries we will choose AdaptiveCpp because its generic compiler feature allows the use of a single binary while maintaining competitive performance.

Naturally, the Just-In-Time (JIT) mechanism introduces a small overhead. However, the authors of @SSCP report that it is of the same order of magnitude as the overhead of compiling IR to machine code, already managed by backend drivers in existing SYCL implementations. Only the first run of the program involves this JIT mechanism when a kernel execution is requested. Kernels are then cached as executable objects so that following runs do not need to retranslate them for the target architecture. To measure it precisely, we rebuilt the SYCL executable 100 times to discard cached kernels and executed it after the CUDA version to isolate the JIT overhead from GPU initialization, which also occurs during the first run of a GPU enabled program (for example, setting up drivers). The obtained mean execution time is $2.49 thick (plus.minus 0.05)$ seconds, giving an average overhead of
$0.42$ seconds. Note that the overhead is independent of the test case size and depends only on the number of instructions and the complexity of the kernel codes.
