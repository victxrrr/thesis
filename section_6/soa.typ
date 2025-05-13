In the previous section, we saw how reordering the mesh can change the distribution of memory addresses accessed by threads and ultimately improve memory coalescence. Although threads access contiguous entries in the array of interfaces or cells, multiple memory transactions may still be required depending on the size of each C++ structure or class instance. Consider a simple example. Assume that cells are represented by a lightweight structure that stores only their hydraulic variables $h$, $p$, $q$ as shown in @aos. When a warp executes an instruction that accesses global memory, it combines the memory accesses of all threads in the warp into as few memory transactions as possible. Global memory is accessed through 32, 64, or 128 byte transactions, and a double precision floating point number is 8 bytes. For this example, we assume a simple kernel that iterates over the cells to access hydraulic variables, as would happen during the update step of the finite volume scheme. 

#import "@preview/cetz:0.3.4": canvas, draw, decorations
#import draw: rect, content, line, grid, mark, circle
#figure(
    gap: 5pt,
    placement: auto,
    scale(90%, 
    canvas({
      
      let c1 = rgb("#fdee97").lighten(0%) //rgb("#b1f2eb")
      let c2 = rgb("#fdac65") //rgb(87, 127, 230)
      let c3 = rgb("#ff5261") // rgb(25%, 13%, 65%)
      let c4 = black
    
      let w_thread = (1/3) * 1
      let inset = .15 * 1

      let N = 24

      let aos(y_off) =  {
        let outset = .15
        let dash_len = .66
        for i in (0, 1) {
            line((-outset + 0*w_thread, y_off + i*w_thread), (N * (w_thread) + outset, y_off + i*w_thread), stroke: c4)
            line((N * (w_thread) + outset, y_off + i*w_thread), (N * (w_thread) + outset + dash_len, y_off + i*w_thread),
                stroke: (dash: "dashed", paint: c4))
            line((-outset + 0*w_thread, y_off + i*w_thread), (-outset - dash_len + 0*w_thread, y_off + i*w_thread), stroke: (dash: "dashed", paint: c4))
        }

        for i in range(0, N) {
            let mod = calc.rem(i, 3)
            if mod == 0 {
                rect(
                  (i * (w_thread), y_off), (i * (w_thread) + w_thread, w_thread + y_off), 
                  fill: c1, stroke: c4
                )
            } else if mod == 1 {
                rect(
                  (i * (w_thread), y_off), (i * (w_thread) + w_thread, w_thread + y_off), 
                  fill: c2, stroke: c4
                )
            } else if mod == 2 {
                rect(
                  (i * (w_thread), y_off), (i * (w_thread) + w_thread, w_thread + y_off), 
                  fill: c3, stroke: c4
                )
            }
        }
      }

      let soa(y_off) =  {
        let outset = .15
        let dash_len = .66
        for i in (0, 1) {
            line((-outset + 0*w_thread, y_off + i*w_thread), (N * (w_thread) + outset, y_off + i*w_thread), stroke: c4)
            line((N * (w_thread) + outset, y_off + i*w_thread), (N * (w_thread) + outset + dash_len, y_off + i*w_thread),
                stroke: (dash: "dashed", paint: c4))
            line((-outset + 0*w_thread, y_off + i*w_thread), (-outset - dash_len + 0*w_thread, y_off + i*w_thread), stroke: (dash: "dashed", paint: c4))
        }

        for i in range(0, N) {
            if i < N / 3 {
                rect(
                  (i * (w_thread), y_off), (i * (w_thread) + w_thread, w_thread + y_off), 
                  fill: c1, stroke: c4
                )
            } else if i >= N/3 and i < 2*N/3 {
                rect(
                  (i * (w_thread), y_off), (i * (w_thread) + w_thread, w_thread + y_off), 
                  fill: c2, stroke: c4
                )
            } else  {
                rect(
                  (i * (w_thread), y_off), (i * (w_thread) + w_thread, w_thread + y_off), 
                  fill: c3, stroke: c4
                )
            }
        }
      }

      let aosoa(y_off) =  {
        let outset = .15
        let dash_len = .66
        for i in (0, 1) {
            line((-outset + 0*w_thread, y_off + i*w_thread), (N * (w_thread) + outset, y_off + i*w_thread), stroke: c4)
            line((N * (w_thread) + outset, y_off + i*w_thread), (N * (w_thread) + outset + dash_len, y_off + i*w_thread),
                stroke: (dash: "dashed", paint: c4))
            line((-outset + 0*w_thread, y_off + i*w_thread), (-outset - dash_len + 0*w_thread, y_off + i*w_thread), stroke: (dash: "dashed", paint: c4))
        }

        for j in (0, 1) {
          for k in range(0, int(N/2)) {
            let i = j * 12 + k
            if k < N/6 {
              rect(
                  (i * (w_thread), y_off), (i * (w_thread) + w_thread, w_thread + y_off), 
                  fill: c1, stroke: c4
                )
            } else if k < 2*N/6 {
              rect(
                  (i * (w_thread), y_off), (i * (w_thread) + w_thread, w_thread + y_off), 
                  fill: c2, stroke: c4
                )
            } else {
              rect(
                  (i * (w_thread), y_off), (i * (w_thread) + w_thread, w_thread + y_off), 
                  fill: c3, stroke: c4
                )
            }
          }
        }
      }

      let line-style = (stroke: .75pt)

      let gap = 2.5

      aosoa(gap*0)

      content(( 28 * w_thread, 0 * gap + w_thread * .5), anchor: "mid-west", [
        ```cpp
        struct BlockCell {
          double h[4], p[4], q[4];
        };
        BlockCell cells[N/4];
        ```
        ])

      content((-.8, 0*gap + w_thread + 3*inset), anchor: "west", [_Array of Structures of Arrays (AoSoA)_])

      soa(gap*1)

      content(( 28 * w_thread, 1 * gap + w_thread * .5), anchor: "mid-west", [
        ```cpp
        struct Cells {
          double h[N], p[N], q[N];
        };
        Cells cells;
        ```
        ])
      content((-.8, 1*gap + w_thread + 3*inset), anchor: "west", [_Structure of Arrays (SoA)_])

      aos(gap*2)

      content(( 28 * w_thread, 2 * gap + w_thread * .5), anchor: "mid-west", [
        ```cpp
        struct Cell {
          double h, p, q;
        };
        Cell cells[N];
        ```
        ])
      
      content((-.8, 2*gap + w_thread + 3*inset), anchor: "west", [_Array of Structures (AoS)_])
    
    })),
    caption : [Data layouts]
    )<aos>

First, all threads in a warp try to retrieve the 
$h$ values. If the cells are stored using an Array of Structures (AoS) layout, only the first 6 threads can coalesce their memory accesses into a single 128 byte transaction, since each 
$(h,p,q)$ triplet takes 24 bytes. As a result, at least 6 transactions are needed to load all 
$h$ values. Although this layout is intuitive for programmers, it leads to poor memory coalescence. On the other hand, since 
$p$ and 
$q$ are accessed in the next instruction, AoS provides good spatial locality because they were already loaded in the previous transaction. An alternative is the Structure of Arrays (SoA) layout, which has been shown to be more efficient in GPU implementations @Xu2016. In this layout, all 
$h$ values are stored in one large array, followed by all 
$p$ values and all 
$q$ values. This enables excellent memory coalescence. In our example, only two transactions are needed to load all 
$h$ values in a warp: one for the first 16 threads and one for the last 16. With FP32, a single transaction is enough. However, SoA has weaker spatial locality, since accesses to 
$h$, 
$p$, and 
$q$ are distant in memory across instructions. Still, it is generally more attractive because GPU caches are much smaller than those on CPUs. \
A final approach combines the best of both layouts and is known as Array of Structures of Arrays (AoSoA). As the name suggests, it uses a tiled block organization that preserves coalescence while also providing good spatial locality. The block size can be tuned experimentally, and index-based access must be carefully managed to align with the tiled structure.

To assess the effectiveness of each memory layout, we preprocessed the original data containers (formerly classes with additional methods to set up geometry) into lightweight structures to better isolate the impact of memory layout. The structure for cells follows the pseudocode of @aos, while similar structures are used for the interfaces with fields for the flux and the indices of the left and right cells. We also added two accesses to the new variables $p$ and $q$ and added $2 dot 10^(-6)$ to both of them in the update kernel. The results of this modified version on the Toce _XL_ case study for each data layout are reported in @soa_times.

#show table.cell.where(y: 0): strong
#set table(
  stroke: (x, y) => if y == 0 {
    (bottom: 0.7pt + black)
  } else if y == 2 or y == 4  {
    (bottom: .35pt)
  },
  align: (x, y) => (
    if x > 0 { center + horizon }
    else { center }
  )
)

#import "@preview/fancy-units:0.1.1": unit, qty
#figure(table(
  columns: (1fr, 1fr),
  table.header(
    [Layout],
    [Duration [#unit[ms]]],
  ),
  [AoS], [$674 thick (plus.minus 21)$],
  [AoS (reordered mesh)], [$749 thick (plus.minus 22)$],
  [*SoA*], [*$516 thick (plus.minus 12)$*],
  [SoA (reordered mesh)], [$536 thick (plus.minus 14)$],
  [AoSoA{4}], [$639 thick (plus.minus 20)$],
  [AoSoA{8}], [$626 thick (plus.minus 13)$],
  [AoSoA{16}], [$599 thick (plus.minus 14)$],
  [AoSoA{32}], [$600 thick (plus.minus 14)$],
  [AoSoA{64}], [$593 thick (plus.minus 14)$],
  [AoSoA{4} (reordered mesh)], [$649 thick (plus.minus 14)$],
  [AoSoA{8} (reordered mesh)], [$654 thick (plus.minus 17)$],
  [AoSoA{16} (reordered mesh)], [$622 thick (plus.minus 16)$],
  [AoSoA{32} (reordered mesh)], [$623 thick (plus.minus 15)$],
  [AoSoA{64} (reordered mesh)], [$629 thick (plus.minus 16)$],

), caption: [Total execution times of the PoC with the modified update kernel])<soa_times>

We observe that the lowest execution times are achieved with the Structure of Arrays layout. Furthermore, the larger the block size used in the AoSoA layout#footnote[Indicated in {...} in the table.], the lower the execution times. This suggests that memory coalescence is more important than cache awareness in GPU algorithms. It is also worth noting that, regardless of the data layout, execution times are overall lower than in the previous sections. For this assessment, we removed all member variables and functions related to mesh geometry, keeping only the hydraulic variables. Reducing the stride between edge and cell instances helps speed up computation. This change should also be preferred in CPU implementations, as running the serial version with this layout yields a mean duration of 15.06 ± 0.187 seconds, resulting in a speedup of 3.74. In the previous version, the suboptimal memory layout was mitigated by reordering the mesh and leveraging cache behavior, but here, reordering provides no benefit regardless of the layout. Worse, it actually increases execution times. As before, we performed a per kernel analysis for further insight, presented in @soa_ker.

#set table(
  stroke: (x, y) => if y == 0 {
    (bottom: 0.7pt + black)
  } else if y == 2 or y == 4  {
    (bottom: .35pt)
  },
  align: (x, y) => (
    if x > 0 { center }
    // else if y == 0 { top }
    else { left  }
  )
)

#import "@preview/subpar:0.2.2"
#subpar.grid(
  placement: auto,
  figure(table(
      columns: (30%, 20%, 25%, 25%),
      table.header(
        [Layout],
        [Duration [#unit[μs]]],
        [Compute \ Throughput [#unit[%]]],
        [Memory \ Throughput [#unit[%]]],
      ),
      [AoS], [$378.09 thick (plus.minus 24.682)$], [$10.21 thick (plus.minus 0.653)$], [$71.89 thick (plus.minus 0.130)$], 
      [AoS (reordered mesh)], [$271.06 thick (plus.minus 18.221)$], [$14.30 thick (plus.minus 0.948)$], [$95.81 thick (plus.minus 0.184)$],
      [SoA], [$140.38 thick (plus.minus 1.013)$], [$27.72 thick (plus.minus 0.204)$], [$65.89 thick (plus.minus 0.503)$],
      [SoA (reordered mesh)], [$96.73 thick (plus.minus 0.238)$], [$42.06 thick (plus.minus 0.192)$], [$94.36 thick (plus.minus 0.141)$],
      [AoSoA{16}], [$195.02 thick (plus.minus 2.531)$], [$40.66 thick (plus.minus 0.526)$], [$80.12 thick (plus.minus 0.125)$],
      [AoSoA{16} (reordered mesh)], [$162.82 thick (plus.minus 0.288)$], [$49.13 thick (plus.minus 0.139)$], [$95.23 thick (plus.minus 0.083)$], 

    ), gap: .75em, caption: [Flux kernel]),  
  figure(table(
    columns: (30%, 20%, 25%, 25%),
    table.header(
      [Framework],
      [Duration [#unit[μs]]],
      [Compute \ Throughput [#unit[%]]],
      [Memory \ Throughput [#unit[%]]],
    ),
    [AoS], [$133.10 thick (plus.minus 0.663)$], [$28.98 thick (plus.minus 0.146)$], [$93.46 thick (plus.minus 0.158)$], 
    [AoS (reordered mesh)], [$133.41 thick (plus.minus 1.945)$], [$28.90 thick (plus.minus 0.378)$], [$93.45 thick (plus.minus 0.163)$], 
    [SoA], [$130.29 thick (plus.minus 2.124)$], [$30.76 thick (plus.minus 0.386)$], [$95.39 thick (plus.minus 0.172)$],
    [SoA (reordered mesh)], [$130.24 thick (plus.minus 2.048)$], [$30.78 thick (plus.minus 0.388)$], [$95.39 thick (plus.minus 0.211)$],
    [AoSoA{16}], [$128.33 thick (plus.minus 2.529)$], [$31.12 thick (plus.minus 0.400)$], [$95.34 thick (plus.minus 0.177)$],
    [AoSoA{16} (reordered mesh)], [$128.09 thick (plus.minus 1.877)$], [$31.11 thick (plus.minus 0.418)$], [$95.34 thick (plus.minus 0.183)$], 
  ), gap: .75em, caption: [Modified update kernel]),
  figure(table(
    columns: (30%, 20%, 25%, 25%),
    table.header(
      [Layout],
      [Duration [#unit[μs]]],
      [Compute \ Throughput [#unit[%]]],
      [Memory \ Throughput [#unit[%]]],
    ),
    [AoS], [$112.10 thick (plus.minus 2.624)$], [$12.32 thick (plus.minus 0.259)$], [$94.44 thick (plus.minus 0.230)$], 
    [AoS (reordered mesh)], [$111.63 thick (plus.minus 0.292)$], [$12.37 thick (plus.minus 0.034)$], [$94.43 thick (plus.minus 0.248)$],
    [SoA], [$44.21 thick (plus.minus 0.544)$], [$32.76 thick (plus.minus 0.460)$], [$83.67 thick (plus.minus 0.711)$],
    [SoA (reordered mesh)], [$44.12 thick (plus.minus 0.363)$], [$32.75 thick (plus.minus 0.243)$], [$83.80 thick (plus.minus 0.750)$],
    [AoSoA{16}], [$45.21 thick (plus.minus 0.352)$], [$31.93 thick (plus.minus 0.263)$], [$81.59 thick (plus.minus 0.687)$],
    [AoSoA{16} (reordered mesh)], [$45.29 thick (plus.minus 0.329)$], [$31.95 thick (plus.minus 0.293)$], [$81.41 thick (plus.minus 0.635)$], 
  ), gap: .75em, caption: [Min reduction]),
  columns: 1,
  caption: [Per-kernel profiling],
  kind: table,
  label: <soa_ker>,
  numbering: n => {
    let h1 = counter(heading).get().first()
    numbering("1.1", h1, n)
  }, gap: 1em
)

The kernel timings align more closely with expectations. In the update kernel, the AoSoA and SoA layouts slightly improve memory throughput, but since throughput was already high in AoS, execution time differences are minor. In contrast, the flux kernel shows more variation. Here, mesh reordering significantly increases bandwidth usage across layouts, reducing mean execution times. Even without reordering, the AoSoA layout with block size 16 benefits from high memory throughput due to its tiled structure. However, compute throughput is also higher because of additional operations needed to access elements in the blocked layout, leading to suboptimal performance compared to SoA. In a more compute-intensive kernel, the indexing overhead may become negligible, making the layout more favorable. SoA generally performs best, especially with mesh reordering, achieving very low timings and showing a speedup of 14x compared to @ncu profiling. Finally, the AoS layout underperforms relative to the other two in the reduction kernel.

// time profiling are realized over 1000 steps, kernel profiling are realized over 100 steps on Toce XL
