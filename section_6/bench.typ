/*

faire un tableau temps d'exec speedup vs Serial ET speedup vs best parallel

*/
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

#import "@preview/fancy-units:0.1.1": num, unit, qty

==== Toce case study

We begin benchmarking our GPU implementation by measuring the mean execution time on the Toce simulation, as in the previous chapter. Results are shown in @toce_timings. We also computed the obtained speedups with respect to the serial and most effecient parallel implementations, i.e. using 14 OpenMP threads and a reordered mesh for the latter.

#figure(placement: none,
table(
  columns: (1fr, 1.25fr, .75fr, .75fr),
  table.header([Version], [Mean Execution Time $[#unit[s]]$], [$"Speedup"_"serial"$], [$"Speedup"_"parallel"$]),
  [GPU], [$1.325 thick (plus.minus 0.039)$], [$12.20$], [$1.55$],
  [GPU (reordering)], [$1.306 thick (plus.minus 0.025)$], [$12.38$], [$1.57$],
  [GPU (variant)], [$1.300 thick (plus.minus 0.024)$], [$12.44$], [$1.58$],
  [GPU (output-free)], [$1.155 thick (plus.minus 0.016)$], [--], [--]
),
caption: [Benchmarks of the GPU implementation on Toce case study]
)<toce_timings>

The GPU capable implementation is the fastest measured so far. It requires less than 2 seconds to run the 53 simulated seconds. The speedup with respect to the serial implementation is about 12. On the other hand, it is only $1.55$ times faster than the parallel version. Besides, the mean execution time on a reordered mesh is slightly reduced. This may be caused by the disruption of interface ordering induced by the removal of polymorphism. Indeed, as explained in @section_poly, separate arrays for each boundary type were instantiated to batch them and launch kernels by type in the computeFluxes function. To do so, mutable vectors are created at runtime to dispatch each interface into the correct batch. This classifying procedure generates conflicts with the numbering strategy presented in @section_reordering, as interface indices were sorted according to left and right cell indices. In the batch vectors, they receive a new index that differs from the optimized original one. To alleviate this issue, the reordering variant of @section_gpu_reordering can be envisaged to isolate the inner interface ordering from the boundary one. This way, most of the optimized interface ordering will not be affected by the classifying process in the GPU preprocessing and the PoC showed no observable overheads introduced by the variant. The timings with the variant in the table are slightly reduced but the difference remains too small to clearly claim it as a solution. However, this may indicate that the low benefits obtained from renumbering the mesh may be caused only by the small size of the test case regardless of the batch classification. Finally, we also recorded the elapsed time when no outputs are requested to isolate the overhead from synchronization and data movements due to output tasks. Based on these results, we estimate that output tasks account for $#qty[12.83][%]$ of the measured wall time in this test case.

To get further insights, kernel profilings of the different flux kernerls are shown in @ncu_toce. We profiled 300 kernel launches after skipping the first 30 000. This corresponds to starting the profiling from about 38 seconds of simulation, therefore guaranteeing a fully wet domain that maximizes computational burden. For each kernel launch, Nsight Compute collects profiling metrics over 8 passes. The reordering strategies mainly impact the flux computations at inner interfaces. However, the gain is only about $#qty[2][nanoseconds]$ and is therefore quite negligible. Regarding the other kernels, differences are too small to conclude anything.

We can now analyze the results on the square basin to see whether they follow the same tendencies.


#import "@preview/subpar:0.2.2"
#show figure: set block(breakable: true)

#subpar.grid(
  figure(table(
      columns: (1fr,1fr,1fr,1fr),
      table.header(
        [Version],
        [Duration #unit[[μs]]],
        [Compute \ Throughput #unit[[%]]],
        [Memory \ Throughput #unit[[%]]],
      ),
      [GPU], [$82.57 thick (plus.minus 0.47)$], [$71.76 thick (plus.minus 0.34)$], [$29.66 thick (plus.minus 0.87)$],
      [GPU (reordering)], [$80.12 thick (plus.minus 0.37)$], [$73.93 thick (plus.minus 0.26)$], [$30.17 thick (plus.minus 0.16)$],
      [GPU (variant)], [$80.02 thick (plus.minus 0.26)$], [$73.82 thick (plus.minus 0.26)$], [$30.29 thick (plus.minus 0.72)$],
    ), gap: .75em, caption: [Flux kernel of inner interfaces (`HydroFluxLHLLC`)]),
  figure(table(
      columns: (1fr,1fr,1fr,1fr),
      table.header(
        [Version],
        [Duration #unit[[μs]]],
        [Compute \ Throughput #unit[[%]]],
        [Memory \ Throughput #unit[[%]]],
      ),
      [GPU], [$5.81 thick (plus.minus 0.11)$], [$5.22 thick (plus.minus 0.10)$], [$6.84 thick (plus.minus 0.34)$],
      [GPU (reordering)], [$5.78 thick (plus.minus 0.08)$], [$5.26 thick (plus.minus 0.08)$], [$6.71 thick (plus.minus 0.20)$],
      [GPU (variant)], [$5.83 thick (plus.minus 0.09)$], [$5.20 thick (plus.minus 0.09)$], [$6.67 thick (plus.minus 0.21)$],
    ), gap: .75em, caption: [Flux kernel of wall interfaces (`HydroBCWall`)]),
  figure(table(
      columns: (1fr,1fr,1fr,1fr),
      table.header(
        [Version],
        [Duration #unit[[μs]]],
        [Compute \ Throughput #unit[[%]]],
        [Memory \ Throughput #unit[[%]]],
      ),
      [GPU], [$9.55 thick (plus.minus 0.09)$], [$2.67 thick (plus.minus 0.03)$], [$1.31 thick (plus.minus 0.09)$],
      [GPU (reordering)], [$9.50 thick (plus.minus 0.07)$], [$2.68 thick (plus.minus 0.02)$], [$1.25 thick (plus.minus 0.05)$],
      [GPU (variant)], [$9.52 thick (plus.minus 0.09)$], [$2.69 thick (plus.minus 0.02)$], [$1.25 thick (plus.minus 0.05)$],
    ), gap: .75em, caption: [Flux kernel of transmissive interfaces (`HydroBCTransmissive`)]),
  figure(table(
      columns: (1fr,1fr,1fr,1fr),
      table.header(
        [Version],
        [Duration #unit[[μs]]],
        [Compute \ Throughput #unit[[%]]],
        [Memory \ Throughput #unit[[%]]],
      ),
      [GPU], [$7.92 thick (plus.minus 0.14)$], [$0.84 thick (plus.minus 0.01)$], [$1.13 thick (plus.minus 0.10)$],
      [GPU (reordering)], [$7.93 thick (plus.minus 0.10)$], [$0.85 thick (plus.minus 0.01)$], [$1.07 thick (plus.minus 0.06)$],
      [GPU (variant)], [$7.87 thick (plus.minus 0.10)$], [$0.84 thick (plus.minus 0.01)$], [$1.06 thick (plus.minus 0.04)$],
    ), gap: .75em, caption: [Flux kernel of hydrograph interfaces (`HydroBCHydrograph`)]),
  columns: 1,
  caption: [Flux kernels profiling with NVIDIA Nsight Compute (Toce)],
  kind: table,
  label: <ncu_toce>,
  numbering: n => numbering("1.1", ..counter(heading.where(level: 1)).get(), n),
  numbering-sub-ref: (..n) => {
    numbering("1.1a", ..counter(heading.where(level: 1)).get(), ..n)
  },
  gap: 1em
)

==== Square basin case study

@basin_timings shows that in this case study the gap further increases between the performances of the GPU implementations and our most efficient CPU parallel one, that is using 16 OpenMP working threads and a reordered mesh, reaching a speedup of 2.53. The speedup of 26.50 with respect to the serial version is considerable. In particular, the ratio of execution time over simulated time is equal to 0.83 even for a mesh with 578 262 cells. The direct implication is that the amount of time needed to produce the simulation will always be smaller than the targeted simulated time. Compared to the serial implementation on the reordered mesh, the speedups are of the same order of magnitude as in the Toce river simulation.

Besides, while the data movements needed by output tasks were expected to be time consuming given the large amount of data to transfer on a limited bandwidth, the overhead compared to the output free execution is only equal to 5.06% of the elapsed time. On the other hand, as before the reordering strategies do not bring any noticeable improvements. To get a better understanding of the possible reasons, a per-kernel profiling was devised on the GPU execution with and without renumbering strategies.

#figure(placement: none,
table(
  columns: (1.25fr, 1.66fr, .75fr, .75fr, .75fr),
  table.header([Version], [Mean Execution Time $#unit[[s]]$], [$"S"_"serial"$],  [$"S"_"serial+reord."$],  [$"S"_"parallel"$]),
  [GPU], [$49.507 thick (plus.minus 0.103)$], [$26.50$], [$12.98$], [$2.53$],
  [GPU (reordering)], [$50.309 thick (plus.minus 0.314)$], [$26.07$], [$12.77$], [$2.49$],
  [GPU (variant)], [$49.181 thick (plus.minus 0.393)$], [$26.67$], [$13.06$], [$2.55$],
  [GPU (output-free)], [$47.004 thick (plus.minus 0.220)$], [--], [--], [--]
),
caption: [Benchmarks of the GPU implementation on Toce case study]
)<basin_timings>

@ncu_basin shows that there are no significant differences in the mean kernel execution times when reordering strategies are employed. The only noticeable difference concerns the memory throughput, which decreased. As this was the opposite of what could be expected, a more detailed analysis was conducted by enabling all metrics of the Nsight Compute profiler. It appeared that the reported memory throughputs refer to the maximum achieved bandwidth by data transfers between L2 cache and device memory. On the other hand, the L2 cache hit rate increased from 51.26% to 58.45%.

In both cases, the profiler reports uncoalesced global accesses resulting in a total of 16 762 283 excessive sectors (74% of the total 22 610 456 sectors) or 15 738 918 excessive sectors (73% of the total 21 587 091 sectors) with the reordered mesh. The profiler predicts that fixing this issue could lead to a theoretical speedup of 73.67% and 67.42% of the kernel runtime, respectively. Furthermore, Nsight Compute indicates that on average, only 8 of the 32 bytes transmitted per sector are utilized by each thread, possibly due to a stride between threads. A sector corresponds to an aligned 32 byte chunk of memory in a cache line or device memory @nvidia_nsight_compute_docs.

Based on all the profiling metrics, two potential reasons can be proposed to justify the lack of efficiency of the reordering compared to the results observed in the Proof of Concept. Firstly, the high number of member variables in cell classes introduces large strides between accessed elements, for example the hydraulic variables or the flux buffer, which reduces the potential coalescence of memory transactions whose sizes range between 1 to 4 sectors or equivalently 4 to 16 double precision floating point numbers. Many of these variables are geometry related and are never accessed after geometry parsing.

Secondly, the kernel is clearly compute bound, as shown by the very high compute throughput. It currently uses 62% of its FP64 peak performance. The profiler estimates a speedup of 83.32% by switching to single precision, as the peak performance ratio is 64 to 1 on the RTX 4050 (Laptop) used. Since the bottleneck lies in the computational workload, additional memory latencies with unordered mesh can be easily overlapped, and the latter should be optimized rather than memory accesses in order to observe performance improvement.

#subpar.grid(
  figure(table(
      columns: (1fr,1fr,1fr,1fr),
      table.header(
        [Version],
        [Duration #unit[[μs]]],
        [Compute \ Throughput #unit[[%]]],
        [Memory \ Throughput #unit[[%]]],
      ),
      [GPU], [$4.278 thick (plus.minus 0.005)$], [$88.634 thick (plus.minus 0.021)$], [$45.739 thick (plus.minus 0.049)$],
      [GPU (reordering)], [$4.276 thick (plus.minus 0.005)$], [$88.722 thick (plus.minus 0.019)$], [$39.511 thick (plus.minus 0.043)$],
      [GPU (variant)], [$4.275 thick (plus.minus 0.005)$], [$88.724 thick (plus.minus 0.015)$], [$39.512 thick (plus.minus 0.033)$],
    ), gap: .75em, caption: [Flux kernel of inner interfaces (`HydroFluxLHLLC`)]),
  figure(table(
      columns: (1fr,1fr,1fr,1fr),
      table.header(
        [Version],
        [Duration #unit[[μs]]],
        [Compute \ Throughput #unit[[%]]],
        [Memory \ Throughput #unit[[%]]],
      ),
      [GPU], [$0.010 thick (plus.minus 0.000)$], [$21.779 thick (plus.minus 0.259)$], [$19.395 thick (plus.minus 0.256)$],
      [GPU (reordering)], [$0.010 thick (plus.minus 0.000)$], [$21.081 thick (plus.minus 0.237)$], [$18.658 thick (plus.minus 0.209)$],
      [GPU (variant)], [$0.010 thick (plus.minus 0.000)$], [$20.854 thick (plus.minus 0.250)$], [$18.587 thick (plus.minus 0.318)$],
  ), gap: .75em, caption: [Flux kernel of wall interfaces (`HydroBCWall`)]),
  figure(table(
      columns: (1fr,1fr,1fr,1fr),
      table.header(
        [Version],
        [Duration #unit[[μs]]],
        [Compute \ Throughput #unit[[%]]],
        [Memory \ Throughput #unit[[%]]],
      ),
      [GPU], [$0.010 thick (plus.minus 0.002)$], [$3.048 thick (plus.minus 0.038)$], [$1.236 thick (plus.minus 0.056)$],
      [GPU (reordering)], [$0.010 thick (plus.minus 0.002)$], [$3.048 thick (plus.minus 0.046)$], [$1.241 thick (plus.minus 0.057)$],
      [GPU (variant)], [$0.010 thick (plus.minus 0.002)$], [$3.062 thick (plus.minus 0.036)$], [$1.245 thick (plus.minus 0.058)$],
    ), gap: .75em, caption: [Flux kernel of transmissive interfaces (`HydroBCTransmissive`)]),
  figure(table(
      columns: (1fr,1fr,1fr,1fr),
      table.header(
        [Version],
        [Duration #unit[[μs]]],
        [Compute \ Throughput #unit[[%]]],
        [Memory \ Throughput #unit[[%]]],
      ),
      [GPU], [$0.010 thick (plus.minus 0.000)$], [$2.338 thick (plus.minus 0.132)$], [$1.687 thick (plus.minus 0.147)$],
      [GPU (reordering)], [$0.010 thick (plus.minus 0.000)$], [$2.338 thick (plus.minus 0.129)$], [$1.675 thick (plus.minus 0.140)$],
      [GPU (variant)], [$0.010 thick (plus.minus 0.000)$], [$2.365 thick (plus.minus 0.129)$], [$1.687 thick (plus.minus 0.150)$],
    ), gap: .75em, caption: [Flux kernel of imposed discharge interfaces (`HydroBCDischarge`)]),
  columns: 1,
  caption: [Flux kernels profiling with NVIDIA Nsight Compute (Toce)],
  kind: table,
  label: <ncu_basin>,
  numbering: n => numbering("1.1", ..counter(heading.where(level: 1)).get(), n),
  numbering-sub-ref: (..n) => {
    numbering("1.1a", ..counter(heading.where(level: 1)).get(), ..n)
  },
  gap: 1em
)

#show: body => {
  for elem in body.children {
    if elem.func() == math.equation and elem.block {
      let numbering = if "label" in elem.fields().keys() {
        n => {
          let h1 = counter(heading).get().first()
          numbering("(1.1)", h1, n)
        }
      } else { none }
      set math.equation(numbering: numbering)
      elem
    } else {
      elem
    }
  }
}

A key difference between executions on this case study and the previous one concerns the observed differences in the results. Indeed, @gpu_diff shows the observed divergent elements in the outputed pictures between the serial and GPU-enabled implementation. Further analysis of differences reveal that it concerns cells corresponding to still water, where the flux balance sums up to zero. This is the same situation highlighted in @precision_section, i.e. as no moving water leads to catastrophic cancelations that emphasis roundoff differences. However, in this case, both execution relies on the same source code and algorithmic patterns. The most likely source is the change in operated hardware. Indeed, we suspect two fundamental differences linked to GPU architectures:

- As explained in @nvidia_cuda_floating_point, the rounding errors related to transcendental functions such as sin, pow or sqrt are library-dependent, in use in Watlab implementation. It can be expected than CUDA implementations yields slightly different results than those used in CPU versions.

- #block[

    #show: body => {
      for elem in body.children {
        if elem.func() == math.equation and elem.block {
          let numbering = if "label" in elem.fields().keys() {
            n => {
              let h1 = counter(heading).get().first()
              numbering("(1.1)", h1, n)
            }
          } else { none }
          set math.equation(numbering: numbering)
          elem
        } else {
          elem
        }
      }
    }

Besides common operations such as additions or multiplications, functional units are also able to combine them to result in a Fused Multiply-Add instruction. It basically allows to perform
$
X times Y + Z
$
in a single operation. Therefore it is often faster as it superses two instructions but also more accurate as the result is only rounded up once while performing the multiplication and after the addition introduce roundoff errors two times. In the 2010s, only NVIDIA GPUs featured hardware units able to perform such instructions while CPUs were not @nvidia_cuda_floating_point. This feature was introduced in Intel processors with Haswell microarchitecture (2013) @haswell and is now spread over most modern processors. However, the use of such instructions is decided by the compiler depeding on depedencies of floating-point additions and multiplications. Therefore, it is quite reasonable to expect that the CUDA compiler fused different instructions than the host compiler. An analysis of the low-level machine code with Nsight Compute revealed the presence of DFMA instructions in Watlab kernel codes.]

#figure(
  image("../img/error_evolution.svg"),
  caption: [Evolution of divergent elements in pictures between serial and GPU implementations]
)<gpu_diff>

@gpu_diff also shows that the proportion of differences decreases over time so does the region of still water in the domain. Therefore, the error does not propagate during the simulation and concerns only values close to 0.

=== OpenMP backend

As mentioned in @poc_section, the AdaptiveCpp enabled implementation can target not only GPUs but also CPUs through OpenMP. To assess any potential overhead compared to the parallel OpenMP based implementation of @parallel_section, execution times on the square basin case study have been recorded to compare performances, shown in @acpp_cpu. The percentage improvement computed as
$
  (T_"OpenMP" - T_"AdaptiveCpp")/T_"OpenMP" times 100 thick #unit[[%]]
$ allows for easier comparison. As shown in @acpp_cpu, the AdaptiveCpp execution with OpenMP as backend originally underperformed compared to the original parallel program. This lack of performance was quite unexpected since both programs rely on the same library and equivalent source code. The only difference comes from the compilers used. The former parallel implementation was compiled with GCC @GCC, whereas the AdaptiveCpp compilation flow is based on the clang compiler @llvm. Therefore, the differences might result from the different levels of default optimizations applied by the two compilers. To verify this, the benchmarks were measured on the AdaptiveCpp implementation compiled with the `-O1` flag, enabling the first level of compiler optimizations. In this case, it appears that when a small number of threads is considered, the AdaptiveCpp implementation performs better. The gap decreases as the number of threads increases until 16 threads, from which point the AdaptiveCpp implementation becomes slightly slower. The AdaptiveCpp documentation @adaptivecpp_performance warns that AdaptiveCpp uses asynchronous worker threads that handle lightweight tasks like garbage collection and may interfere with OpenMP threads. To verify this, a threading analysis with Intel Advisor was performed on the Toce case study, for which reference data is available, to observe how the contention metrics evolve.

#figure(placement: auto,
table(
  columns: (1fr, 1.25fr, 1fr),
  table.header([OpenMP threads], [Mean Execution Time $#unit[[s]]$], [Improvement $#unit[[%]]$]),
  [$2$], [$3#unit[m]46.02 thick (plus.minus 3.43)$], [$+17.60$],
  [$4$], [$2#unit[m]37.14 thick (plus.minus 1.60)$], [$+11.51$],
  [$8$], [$2#unit[m]22.88 thick (plus.minus 0.69)$], [$+3.42$],
  [$12$], [$2#unit[m]08.05 thick (plus.minus 0.19)$], [$+4.29$],
  [$14$], [$2#unit[m]06.05 thick (plus.minus 0.36)$], [$+1.88$],
  [$16$], [$2#unit[m]08.09 thick (plus.minus 0.90)$], [$-2.22$],
  [$20$], [$2#unit[m]52.59 thick (plus.minus 1.11)$], [$-8.05$],
),
caption: [Benchmarks of the AdaptiveCpp implementation with OpenMP backend (basin)]
)<acpp_cpu>

Although the above optimized version allows for execution times of the same order of magnitude as the original parallel version, it has a main drawback. Some of the optimizations introduced by the -O1 flag alter the floating point accuracy, resulting in divergent elements in the output pictures, whose evolution is described in @acpp_diff. The behavior of these irregularities is similar to the one reported for the CUDA backend in @gpu_diff, again involving no moving water and not appearing to propagate over the simulation. Nevertheless, additional work was done to identify the problematic optimizations, and by trial and error, adding the -fno-unsafe-math-optimizations flags removed the diverging elements completely. Under the hood, this compiler flag disables five others according to the clang user manual @clang_manual
#let unbold(it) = text(weight: "thin", it)
- #unbold(`fno-approx-func`): disallows replacing math function calls with approximately equivalent instructions, e.g. `pow(x, 0.25) ~ sqrt(sqrt(x))`.

- #unbold(`fno-associative-math`):  disallows reassociating floating point operations.

- #unbold(`fno-reciprocal-math`): disallows transforming floating point divisions into equivalent multiplications by a reciprocal, e.g `x / y ~ x * (1 / y)`.

- #unbold(`fno-signed-zeros`): disallows optimizations that ignore the signs of zeroes, e.g. `x = x + 0.0 ~ x = x`.

- #unbold(`ffp-contract=on`): enables FMA fusion for operations in the same statements only.

#figure(
  image("../img/error_evolution_o1.svg"),
  caption: [Evolution of divergent elements in pictures between serial and GPU implementations]
)<acpp_diff>
