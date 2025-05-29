=== Execution <warpdiv_sec>

CUDA C++ handles the heterogeneity of GPU architectures by introducing the thread abstraction, which represents the smallest unit of execution and corresponds to a sequence of instructions run on the cores of an SM. In practice, developers define a function to be executed on the GPU much like a regular C++ function, as follows:

#block(breakable: true)[
```cpp
// Regular function
void updateCPU(Cell *cells, int n_cells)
{
  for (int i = 0; i < n_cells; i++)
  {
    cells[i].U += ...;
  }
}

// GPU's version
__global__ void updateGPU(Cell *cells, int n_cells)
{
  int i = blockIdx.x * blockDim.x + threadIdx.x;
  if (i < n_cells)
  {
    cells[i].U += ...;
  }
}

updateGPU<<<blocksPerGrid, threadsPerBlock>>>(...);
```
]

The function compiled to run on the GPU is called a kernel and is marked by the `__global__` keyword from the CUDA C++ extension. In this case, it corresponds to writing a single iteration of the `for` loop we aim to parallelize in the CPU version. The kernel body must be executed for many values of `i`, representing each cell index. The resulting sequences of instructions for each index are the threads.

To determine which core of which multiprocessor runs each thread, CUDA uses a hierarchical organization. Threads are grouped into blocks, and blocks are distributed across available SMs. The number of threads per block is defined by the user and passed through the `threadsPerBlock` variable using the _execution configuration_ syntax `<<<...>>>`, another CUDA extension.

#import "@preview/cetz:0.3.4": canvas, draw, decorations
#import draw: rect, content, line, grid, mark, circle

#figure(
scale(90%,
canvas({

  let sm_color = teal.lighten(30%)
  let mem_color = yellow.lighten(60%)
  let core_color = green
  let chip_color = gray.lighten(80%)
  let chip_edge = gray.lighten(0%)

  let w = 8
  let t_len = 1.5
  let inset = 1/3
  let cpu_w = 3
  let gap = 4.5

  rect((0, 0), (cpu_w, w + .4), fill: chip_color, stroke: gray, radius: .5)
  content((cpu_w/2, w -.15), [
    #set text(size: 13pt)
    *Host (CPU)*
  ])



  rect((gap, 0), (gap+w, w+.4), fill: chip_color, stroke: gray, radius: .5)
  content((gap+w/2, w -.15), [
    #set text(size: 13pt)
    *Device (GPU)*
  ])

  let thread(A) = {
    decorations.wave(
      line(A, (A.at(0), A.at(1) - t_len)),
      amplitude: .07,
      segments:7,
      // mark: (end: "stealth"),
      start: 10%,
      stop: 90%,
      stroke: (thickness: 1pt)
    )
    mark(symbol: "stealth", (A.at(0), A.at(1) - t_len - .18), (A.at(0), A.at(1) - t_len - 1), length: .2, stroke: 1pt, scale: .6, fill: black)
  }

  let h = .7
  let s = 2.75
  rect((0+inset, w * h + s*inset), (cpu_w - inset, w * h + cpu_w/4 + s*inset), fill: mem_color, name: "host_memory")
  content("host_memory", [Memory])

  rect((gap+2*inset, w * h + s*inset), (gap + w - 2*inset, w * h + cpu_w/4 + s*inset), fill: mem_color, name: "dev_memory")
  content("dev_memory", [Global memory])

  let double_arr(name1, name2, ..args) = {
    line(name1, name2, mark: (
      start: ">",
      end: ">",
      scale: .75,
      fill: black,
    ), ..args
    )
  }

  double_arr("host_memory", "dev_memory", name: "myarr")
  content("myarr", [DMA], anchor: "south", padding: .2)

  rect((gap + 1*inset, 1*inset), (gap+ w - 1*inset , 1*inset + 0.72*w), stroke: (dash: "dashed"), radius: .5)

  let block_w = w/5
  let block_h = 1.1*w/3
  let corner =(gap + 2*inset, 2*inset + cpu_w/4 + 2.35*inset)
  rect(corner, (corner.at(0) + block_w, corner.at(1) + block_h), fill: sm_color, name: "b1")
  for v in range(0, 4) {
    thread((corner.at(0) + inset + (v)*block_w/5, corner.at(1) + .65 * block_h))
  }
  content((corner.at(0) + block_w/2, corner.at(1)+ .825*block_h), [Block])
  rect((corner.at(0), 2*inset), (corner.at(0) + block_w, 2*inset + cpu_w/3), fill: mem_color, name: "sh1")
  content("sh1", [
    #set align(center + horizon)
    Shared\ #v(-10pt) memory]
  )
  double_arr("b1.north", (corner.at(0) + block_w/2, w * h + s*inset))

  corner.at(0) = corner.at(0) + inset + block_w
  rect(corner, (corner.at(0) + block_w, corner.at(1) + block_h), fill: sm_color, name: "b2")
  for v in range(0, 4) {
    thread((corner.at(0) + inset + (v)*block_w/5, corner.at(1) + .65 * block_h))
  }
  content((corner.at(0) + block_w/2, corner.at(1)+ .825*block_h), [Block])
  rect((corner.at(0), 2*inset), (corner.at(0) + block_w, 2*inset + cpu_w/3), fill: mem_color, name: "sh2")
  content("sh2", [
    #set align(center + horizon)
    Shared\ #v(-10pt) memory]
  )
  double_arr("b2.north", (corner.at(0) + block_w/2, w * h + s*inset))

  let tmp = corner.at(0) + block_w
  corner.at(0) = w - 2*inset - block_w +  gap
  rect(corner, (corner.at(0) + block_w, corner.at(1) + block_h), fill: sm_color, name: "b3")
  for v in range(0, 4) {
    thread((corner.at(0) + inset + (v)*block_w/5, corner.at(1) + .65 * block_h))
  }
  content((corner.at(0) + block_w/2, corner.at(1)+ .825*block_h), [Block])
  rect((corner.at(0), 2*inset), (corner.at(0) + block_w, 2*inset + cpu_w/3), fill: mem_color, name: "sh3")
  content("sh3", [
    #set align(center + horizon)
    Shared\ #v(-10pt) memory]
  )
  double_arr("b3.north", (corner.at(0) + block_w/2, w * h + s*inset))

  double_arr("sh1", "b1.south")
  double_arr("sh2", "b2.south")
  double_arr("sh3", "b3.south")

  content(((tmp + corner.at(0))/2, 2*inset+block_h/2 + cpu_w/4 + 2*inset), [
    #set text(size: 16pt)
    *. . .*
  ])
  content(((tmp + corner.at(0))/2, 2*inset+block_h/2 + cpu_w + 1.5*inset), [
    #set text(size: 13pt)
    Grid
  ])

  line((cpu_w/3, 1*inset + 0.72*w), (cpu_w/3, inset), mark: (end: ">", fill: black), name: "exec")
  content((cpu_w/3 - .4, 1*inset + (1/2)*0.72*w), [Serial execution], angle: 90deg)
  let p = (cpu_w/3, 1*inset + (1/5)*0.72*w)
  circle(p, fill: black, radius: .075)
  content((p.at(0)+.85, p.at(1)), [Kernel])
  line((p.at(0)+1.66, p.at(1)), (p.at(0)+1.66+2.1766, p.at(1)), mark: (end: ">", fill: black, scale: .75))
  let p = (cpu_w/3, 1*inset + (4/5)*0.72*w)
  circle(p, fill: black, radius: .075)
  content((p.at(0)+.85, p.at(1)), [Kernel])
  line((p.at(0)+1.66, p.at(1)), (p.at(0)+1.66+2.1766, p.at(1)), mark: (end: ">", fill: black, scale: .75))
  let p = (cpu_w/3, 1*inset + (1/2)*0.72*w)
  circle(p, fill: black, radius: .075)
  content((p.at(0)+.85, p.at(1)), [Kernel])
  line((p.at(0)+1.66, p.at(1)), (p.at(0)+1.66+2.1766, p.at(1)), mark: (end: ">", fill: black, scale: .75))

  //grid((0,0), (w, w), help-lines: true)
})),
caption : [CUDA thread hierarchy (adapted from @cuda_diagram)]
)<thread_hierarchy>


Since the number of threads in a block may exceed the number of available cores in an SM, each block is split into warps of 32 threads. Warps are executed concurrently and scheduled by the SM's schedulers. Traditionally, all threads in a warp shared the same _program counter_, which holds the address of the next instruction. As a result, they executed the same instruction in lockstep.

A major drawback of this model appears with conditional branches. When some threads follow an if-branch while others do not, only the active ones execute while the rest are masked and wait. Once that path completes, the others execute. These paths are serialized and run one after the other#footnote[Starting with the _Volta_ architecture (Compute Capability 7.0), threads have independent program counters. When divergence occurs, execution paths are interleaved, enabling intra-warp synchronization]. This behavior is called _warp divergence_ and should be avoided to maximize parallel efficiency. @warp_div illustrates this phenomenon with a dummy pseudocode.

#figure(
placement: auto,
scale(90%,
canvas({

  let sm_color = teal.lighten(30%)
  let mem_color = yellow.lighten(60%)
  let core_color = green
  let chip_color = gray.lighten(80%)
  let chip_edge = gray.lighten(0%)

  let w = 8
  let w_thread = (1/3) * .8
  let inset = .15 * 1

  let mask = (1, 4, 5, 6, 7, 8, 13, 14, 15, 21, 22, 23, 24, 25, 26, 27, 28, 29)
  let compl = (0, 2, 3, 9, 10, 11, 12, 16, 17, 18, 19, 20, 30, 31, 32)

  let off = 0

  let row(y_off, mask) =  {
    for i in range(0, 32) {
      if i in mask {
        rect(
          (inset + i * (w_thread + inset), y_off), (inset + i * (w_thread + inset) + w_thread, w_thread + y_off),
          fill: core_color,
        )
      } else {
        rect(
        (inset + i * (w_thread + inset), y_off), (inset + i * (w_thread + inset) + w_thread, w_thread + y_off),
          stroke: (paint: red, dash: "dashed"),
        )
      }
    }
  }

  row(0, range(0, 32))
  row(2 * (inset + w_thread), mask)
  row(3 * (inset + w_thread), mask)
  row(5 * (inset + w_thread), compl)
  row(6 * (inset + w_thread), compl)
  row(7 * (inset + w_thread), compl)
  row(9 * (inset + w_thread), range(0, 32))

  line((-.35, 10 * (inset + w_thread) - inset), (-.35, 0), mark: (end: ">", fill: black))
  content((-.75, 5 * (inset + w_thread) - inset/2), [Time], angle: 90deg)

  for i in (1, 8, 16, 24, 32) {
    content((inset + w_thread/2 + (i -1) * (w_thread + inset), 10 * (inset + w_thread) + 1.5*inset),  [#i])
  }

  let y_off = 9 * (inset + w_thread)
  content((inset + 32 * (w_thread + inset) + w_thread/2, y_off + w_thread/2), anchor: "west", [```cpp // Coherent code```])
  y_off = 8 * (inset + w_thread)
  content((inset + 32 * (w_thread + inset) + w_thread/2, y_off + w_thread/2), anchor: "west", [```cpp if (condition) {```])
  y_off = 7 * (inset + w_thread)
  content((inset + 32 * (w_thread + inset) + w_thread/2, y_off + w_thread/2), anchor: "west", [```cpp    X;```])
  y_off = 6 * (inset + w_thread)
  content((inset + 32 * (w_thread + inset) + w_thread/2, y_off + w_thread/2), anchor: "west", [```cpp    Y;```])
  y_off = 5 * (inset + w_thread)
  content((inset + 32 * (w_thread + inset) + w_thread/2, y_off + w_thread/2), anchor: "west", [```cpp    Z;```])
  y_off = 4 * (inset + w_thread)
  content((inset + 32 * (w_thread + inset) + w_thread/2, y_off + w_thread/2), anchor: "west", [```cpp } else {```])
  y_off = 3 * (inset + w_thread)
  content((inset + 32 * (w_thread + inset) + w_thread/2, y_off + w_thread/2), anchor: "west", [```cpp    A;```])
  y_off = 2 * (inset + w_thread)
  content((inset + 32 * (w_thread + inset) + w_thread/2, y_off + w_thread/2), anchor: "west", [```cpp    B;```])
  y_off = 1 * (inset + w_thread)
  content((inset + 32 * (w_thread + inset) + w_thread/2, y_off + w_thread/2), anchor: "west", [```cpp }```])
  y_off = 0 * (inset + w_thread)
  content((inset + 32 * (w_thread + inset) + w_thread/2, y_off + w_thread/2), anchor: "west", [```cpp // Coherent code```])

  //grid((0,0), (w, w), help-lines: true)
})),
caption : [Warp divergence (adapted from @Brodtkorb2013)]
)<warp_div>

Another important consideration is the number of threads per block. Since warp size is fixed at 32, the block size should be a multiple of 32. For example, if 48 threads are assigned to a block, two warps of 32 are created, but only 48 threads are active. The extra 16 threads in the second warp remain idle, and their results are discarded when execution ends. Blocks can also be one, two, or three dimensional for convenience. For example, applications that work with matrices may find two-dimensional blocks more suitable for partitioning data. \
Finally, thread blocks are organized into a grid to complete the thread hierarchy. The grid can also be one, two, or three dimensional. In the code snippet above, both the block and grid are assumed to be one dimensional. The global thread index, which corresponds to the cell to be processed, is computed using:
#let unbold(it) = text(weight: "thin", it)
/ #unbold(`blockIdx.x`): the block index within the grid along the x direction

/ #unbold(`blockDim.x`): the number of threads per block along the x direction

/ #unbold(`threadIdx.x`): the thread's local index within the block along the x direction
The discussed organization is schematized in @thread_hierarchy, where threads are depicted by wavy arrows.

To conclude, GPU execution features multiple levels of concurrency. At the highest level, multiprocessors execute blocks in parallel. Within each multiprocessor, warps are executed concurrently using the SM's resources, either interleaved or simultaneously depending on the number of schedulers and available cores. Finally, threads within a warp run in parallel on the SM's CUDA cores.

=== Memory

The CUDA memory hierarchy includes three logical address spaces. Each thread has its own private local memory. All threads within a block can access a shared memory space, which exists for the lifetime of the block. In modern NVIDIA GPUs, this shared memory is located in the L1 cache, providing faster access. The largest memory space is global memory, which mainly consists of VRAM, along with cache partitions that help speed up memory transactions. Data stored in global memory is accessible to all threads and persists across kernel launches by the same program.

To process data on the device, it must first be transferred into global memory from the host. This transfer is handled over the PCIe (Peripheral Component Interconnect Express) bus using Direct Memory Access (DMA), a mechanism that enables memory transfers without CPU involvement. The PCIe bus has limited bandwidth and can become a bottleneck for performance @COLINDEVERDIERE201178. For example, it peaks at 15.75 GB/s on our system, while the global memory bandwidth of our NVIDIA RTX 4050 reaches 216.0 GB/s.

Despite this high bandwidth, global memory has significant latency. Fetching a single element can take hundreds of clock cycles @Brodtkorb2013. To reduce this overhead, individual memory transactions should be minimized. Once a transaction is initiated, it should transfer as much data as possible to make effective use of the available bandwidth. \
Furthermore, the CUDA programming manual @nvidia2024cuda explains that when a warp executes an instruction accessing global memory, the memory accesses of its threads are coalesced into one or more memory transactions. The number of transactions depends on the size of the word accessed by each thread and how memory addresses are distributed across the threads. While word size is mostly outside the programmer's control, the memory layout can be adjusted so that nearby threads access nearby data. This optimization technique, known as _memory coalescing_, is essential for achieving efficient GPU performance.

Another key technique GPUs use to maximize performance is _latency hiding_. When a warp stalls on a memory fetch, the GPU quickly switches to another ready-to-run warp, avoiding idle time. This fast context switching requires each streaming multiprocessor to have enough warps to choose from. This is captured by the _occupancy_, defined as the ratio of active warps on an SM to the theoretical maximum it can support. The number of active warps depends not only on block size but also on each thread's resource usage, such as registers and shared memory. However, higher occupancy does not always mean better performance. Once memory latency is fully hidden, increasing occupancy further can reduce per-thread resources and hurt overall performance.

These considerations show that GPGPU is not a miracle solution for speeding up every algorithm. It is effective only for highly parallel tasks that can fully utilize hardware resources by reaching sufficient occupancy. Given the high memory latency, the number of floating-point operations should outweigh memory accesses. Colin de Verdière @COLINDEVERDIERE201178 suggests a minimum ratio of two operations per memory access to make efficient use of a GPU.
