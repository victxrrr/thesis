Concerning OpenMP loops, OpenMP provides several scheduling policies that can be passed to the compiler using the #raw("schedule(<policy>, <block_size>)") keyword in the directive. 
Users can choose between `static`, `dynamic`, or `guided` scheduling policies. In static scheduling, loop iterations are split into contiguous blocks of roughly equal size at compile time and assigned to threads. The `block_size` argument can reduce block size and distribute them cyclically among threads. Dynamic scheduling assigns blocks at runtime, adding overhead. Threads receive a new block of size `block_size` as soon as they finish the previous one. If not specified, `block_size` defaults to 1. Guided scheduling is a dynamic strategy with decreasing block sizes.
The scheduler chooses a block size proportional to $max(#raw("block_size"), #raw("unassigned_iterations / num_threads"))$.

A diagram summarizing the different strategies for 4 threads is shown in @policies.

#let scale_width(canvas) = {
  context {
    let canvas-size = measure(canvas)
    layout(size => {
      scale(size.width/canvas-size.width * 100%, canvas)
    })  
  }
}

#import "@preview/fletcher:0.5.2" as fletcher: diagram, node, edge
#figure(
  scale_width( 
  diagram(
	spacing: 8pt,
	cell-size: (8mm, 10mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
  //node-fill: luma(94%),
	node-outset: 3pt,
  debug: 0,

  edge((-1, -.75), (15, -.75)),
  edge((-1, -1.5), (15, -1.5)),
  for v in range(0, 17) {
    edge((-1 + v * 1, -.75), (-1+ v * 1, -1.5))
  },
  let dh = 1.5,
  edge((-1, -.75 + dh), (15, -.75 + dh)),
  edge((-1, -1.5 + dh), (15, -1.5 + dh)),
  for v in range(0, 5) {
    edge((-1 + v * 4, -.75 + dh), (-1+ v * 4, -1.5 + dh))
  },

  dh = dh + dh,
  edge((-1, -.75 + dh), (15, -.75 + dh)),
  edge((-1, -1.5 + dh), (15, -1.5 + dh)),
  for v in range(0, 9) {
    edge((-1 + v * 2, -.75 + dh), (-1+ v * 2, -1.5 + dh))
  },

  dh = dh + 1.5,
  edge((-1, -.75 + dh), (15, -.75 + dh)),
  edge((-1, -1.5 + dh), (15, -1.5 + dh)),
  for v in range(0, 17) {
    edge((-1 + v * 1, -.75 + dh), (-1+ v * 1, -1.5 + dh))
  },

  dh = dh + 1.5,
  edge((-1, -.75 + dh), (15, -.75 + dh)),
  edge((-1, -1.5 + dh), (15, -1.5 + dh)),
  for v in (0, 4, 7, 10, 12, 13, 14, 15, 16) {
    edge((-1 + v * 1, -.75 + dh), (-1+ v * 1, -1.5 + dh))
  },
  let y = 105mm,
  let off = 19.25mm,
  node((15mm, y), [16 iterations]),
  y = y - off,
  node((20mm, y), [#raw("schedule(static)")]),
  y = y - off,
  node((23mm, y), [#raw("schedule(static, 2)")]),
  y = y - off,
  node((21mm, y), [#raw("schedule(dynamic)")]),
  y = y - off,
  node((20mm, y), [#raw("schedule(guided)")]),

  let y_text = 1.875,

  node((1, y_text -1.5), [$T_1$]),
  node((5, y_text -1.5), [$T_2$]),
  node((9, y_text -1.5), [$T_3$]),
  node((13, y_text -1.5), [$T_4$]),
 
  node((0, y_text), [$T_1$]),
  node((2, y_text), [$T_2$]),
  node((4, y_text), [$T_3$]),
  node((6, y_text), [$T_4$]),
  node((0+8, y_text), [$T_1$]),
  node((2+8, y_text), [$T_2$]),
  node((4+8, y_text), [$T_3$]),
  node((6+8, y_text), [$T_4$]),

  for v in range(0, 16, step: 4) {
    let pos = (-.5 + v, y_text  +1.5)
    if v == 0 {
      node(pos, [$T_1$])
     } else if v == 4 {
      node(pos, [$T_4$])
     } else if v == 8{
      node(pos, [$T_2$])
     } else {
      node(pos, [$T_1$])
     }
  },
  for v in range(0, 16, step: 4) {
    let pos = (-.5 + v + 1, y_text  +1.5)
    if v == 0 {
      node(pos, [$T_2$])
     } else if v == 4 {
      node(pos, [$T_3$])
     } else if v == 8{
      node(pos, [$T_4$])
     } else {
      node(pos, [$T_3$])
     }
  },
  for v in range(0, 16, step: 4) {
    let pos = (-.5 + v + 2, y_text  +1.5)
    if v == 0 {
      node(pos, [$T_3$])
     } else if v == 4 {
      node(pos, [$T_2$])
     } else if v == 8{
      node(pos, [$T_1$])
     } else {
      node(pos, [$T_4$])
     }
  },
  for v in range(0, 16, step: 4) {
    let pos = (-.5 + v + 3, y_text  +1.5)
    if v == 0 {
      node(pos, [$T_4$])
     } else if v == 4 {
      node(pos, [$T_1$])
     } else if v == 8{
      node(pos, [$T_3$])
     } else {
      node(pos, [$T_2$])
     }
  },

  node((1, y_text+2*1.5), [$T_1$]),
  node((4.5, y_text+2*1.5), [$T_2$]),
  node((7.5, y_text+2*1.5), [$T_3$]),
  node((10, y_text+2*1.5), [$T_4$]),
  node((11.5, y_text+2*1.5), [$T_1$]),
  node((12.5, y_text+2*1.5), [$T_2$]),
  node((13.5, y_text+2*1.5), [$T_3$]),
  node((14.5, y_text+2*1.5), [$T_4$]),

)), caption: [Scheduling policies]
)<policies>

Naturally, the overhead of dynamic scheduling is offset by its ability to better handle load imbalance. When iterations vary in computational cost, some threads may remain idle while others are still processing, resulting in uneven workload distribution and reduced parallel efficiency. A static partitioning cannot account for this variation and is more prone to load imbalance. \
In Watlab, imbalance stems from the presence of dry and wet cells. No flux or source terms are computed between two dry cells, making iterations over wet cells longer and requiring careful distribution among threads. Thus, the parallel flux and source term steps in each finite-volume time step likely benefit from dynamic scheduling. In contrast, updating the hydraulic variables is more uniform, mainly summing cell flux buffers that are zero for dry cells, making static scheduling more appropriate. To confirm this, we analyzed the mean execution time of each computational kernel during the Toce simulation (@kernel_policies).

#figure(
  placement: auto,
  image("../img/policies.svg"),
  caption: [Mean kernel execution time with each scheduling policy]
)<kernel_policies>

We observe that guided scheduling is the most efficient for all steps with the default block size. When varying the block size, timings remain fairly stable, though chunks of 500 iterations appear to be a good choice. However, this value likely depends on the mesh studied, so we retain the default. Increasing the block size brings performance closer to that of guided scheduling but remains more variable. In contrast, the static policy suffers significantly from load imbalance and performs much worse than the other two.