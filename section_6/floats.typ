A final point is that GPUs were originally built for graphics, where floating point precision matters less than in scientific computing. As a result, more transistors were historically dedicated to FP32 units than FP64. FP32 also uses half the memory of FP64, effectively doubling bandwidth. \
On high end datacenter hardware like the NVIDIA A100 (CC 8.0) or H100 (CC 9.0), double precision throughput is about half that of single precision, as shown in @TableArithmetic. On consumer GPUs designed for gaming or video editing, the gap is much larger. For example, on our NVIDIA RTX 4050 (CC 8.9), FP64 throughput is 64 times slower than FP32.
Therefore, if a scientific application can tolerate reduced precision, it is always more efficient to use single precision.

To illustrate the impact of arithmetic precision on GPU performance, we implemented a version of the SYCL code using the Structure of Arrays layout with reordered mesh, replacing doubles with floats. As before, profiling metrics are reported in @float_prof.

#show table.cell.where(y: 0): strong
#set table(
  stroke: (x, y) => if y == 0 {
    (bottom: 0.7pt + black)
  },
  align: (x, y) => (
    if x > 0 { center + horizon }
    else { left }
  )
)

#import "@preview/fancy-units:0.1.1": unit, qty
#import "@preview/subpar:0.2.2"

#subpar.grid(
  figure(table(
  columns: (1fr, 1fr),
  table.header(
    [Layout (precision)],
    [Duration [#unit[s]]],
  ),
  [SoA (reordered mesh + floats)], [$260 thick (plus.minus 16)$],
), caption: [Total execution time]),
<floats_total>,
  figure(table(
    columns: (16%, 21%, 31.5%, 31.5%),
    table.header(
      [Kernel],
      [Duration [#unit[μs]]],
      [Compute Throughput [#unit[%]]],
      [Memory Throughput [#unit[%]]],
    ),
    [Flux], [$72.28 thick (plus.minus 2.559)$], [$20.21 thick (plus.minus 0.645)$], [$94.63 thick (plus.minus 0.130)$],
    [Update], [$55.64 thick (plus.minus 2.042)$], [$20.68 thick (plus.minus 0.688)$], [$93.25 thick (plus.minus 0.196)$],  
    [Reduction], [$33.98 thick (plus.minus 0.504)$], [$8.55 thick (plus.minus 0.127)$], [$55.85 thick (plus.minus 1.018)$], 
  ), caption: [Per-kernel profilings]),
  <float_ker>,
  columns: 1,
  caption: [Profile of AdaptiveCpp implementation with FP32 precision],
  kind: table,
  label: <float_prof>
)

Although this proof of concept is memory bound rather than compute bound, total execution time is reduced by about a factor of two. Kernel profiles show lower timings despite decreased compute throughput, indicating that FP32 resources remain underutilized. The update kernel is now over twice as fast, and the other two also show notable gains.

A single-precision version of the Watlab solver could be worth exploring, as the numerical schemes already introduce approximation errors and the hydraulic solver often relies on simplifying assumptions, especially in flood studies. A faster, less precise version could provide quick preliminary estimates before running more detailed and time-consuming simulations.

 