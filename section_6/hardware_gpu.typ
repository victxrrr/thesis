// cuda abstraction warps exists because number of SMs may vary from one GPU to another thus needed to ensure scalability

// more transistors devoted to data processing --> less memory logic to hide latencies 


Graphics Processing Units are built around an array of Streaming Multiprocessors#footnote[For AMD chips, these are called _Compute Units_. The rest of the section focuses on NVIDIA's terminology and architecture, which dominates the HPC community. Other vendors' hardware is broadly similar apart from naming.] @nvidia2024cuda. Each SM contains a fixed number of cores, which are processing units capable of executing instructions, shown in #text("green", fill: green) on @gpu_arch. \
The capabilities of these SMs vary between generations and are defined by the GPU's _Compute Capability_ (CC). For example, the throughput of single and double precision arithmetic instructions per clock cycle for various Compute Capabilities is reported in @TableArithmetic. The cores within each SM are simple and execute the same instruction at the same time, following the Single Instruction, Multiple Threads (SIMT) paradigm. \
@gpu_arch also shows the memory hierarchy. L1 caches are private to each SM, while the larger L2 cache is shared across all SMs. Access to the off-chip device memory, known as _Video Random Access Memory_ (VRAM), goes through the L2 cache. Since the number of SMs varies between GPUs, NVIDIA introduced the CUDA programming model to abstract execution and memory, allowing programs to scale transparently with the number of cores available on the hardware.

#import "@preview/cetz:0.3.4": canvas, draw
#import draw: rect, content, line, grid

#figure(
gap: -15pt,
placement: auto,
scale(75%, 
canvas({
  
  let sm_color = teal.lighten(30%)
  let mem_color = yellow.lighten(60%)
  let core_color = green
  let chip_color = gray.lighten(80%)
  let chip_edge = gray.lighten(0%)

  let w = 8
  let w_sm = w/5

  let fs = 14pt
  
  let a = (0,0)
  rect(a, (a.at(0)+w, a.at(1)+w+2.25), fill: chip_color, stroke: chip_edge, radius: .75)

  let off = .5
  let a_dram = (a.at(0)+off, a.at(1)+off)
  rect(a_dram, (a_dram.at(0) + w - 2*off, a_dram.at(1) + w_sm), fill: mem_color,stroke: black, name: "DRAM")
  content("DRAM", [#set text(size: fs) 
  VRAM])

  a_dram.at(1) = a_dram.at(1) + 2 * off + w_sm

  rect(a_dram, (a_dram.at(0) + w - 2*off, a_dram.at(1) + w_sm), fill: mem_color,stroke: black, name: "L2")
  content("L2", [#set text(size: fs) 
  L2])

  a_dram.at(1) = a_dram.at(1) + 2*off + w_sm

  let old = a_dram

  let sm(a, label) = {
    rect(a, (a.at(0) + w_sm, a.at(1) + w_sm), fill: sm_color,stroke: black, name: label)
    content((a.at(0) + w_sm/2, a.at(1) + 0.75*w_sm) , [#set text(size: fs) 
    SM])
    let dl = .2
    let s = .75pt
    let height = (4/5)*w_sm -3* dl
    let width = w_sm - 2*dl
    rect((a.at(0) + dl, a.at(1) + dl), (a.at(0) - dl + w_sm, a.at(1) + dl + height), stroke: s, fill: core_color)
    
    for i in range(1, 4) {
      line((a.at(0) + dl, a.at(1) + dl + i*height/4), (a.at(0) - dl + w_sm, a.at(1) + dl + i*height/4), stroke: s)
    }
    for i in range(1, 8) {
      line((a.at(0) + dl + i*width/8, a.at(1) + dl), (a.at(0) + dl + i*width/8, a.at(1) + dl + height), stroke: s)
    }
  }
  sm(a_dram, "SM1")
  a_dram.at(0) = a_dram.at(0) + off + w_sm
  sm(a_dram, "SM2")
  a_dram.at(0) = a_dram.at(0) + 6.5*off
  sm(a_dram, "SM3")

  content((5.05, a_dram.at(1) + w_sm/2 + .1), [
    #set text(size: 16pt)
    *. . .*
  ])

  old.at(1) = old.at(1) + w_sm + 1.5*off
  rect(old, (old.at(0) + w_sm, old.at(1) + w_sm/2), fill: mem_color, name: "L11")
  content("L11", [#set text(size: fs) 
  L1])
  old.at(0) = old.at(0) + w_sm + off
  rect(old, (old.at(0) + w_sm, old.at(1) + w_sm/2), fill: mem_color, name: "L12")
  content("L12", [#set text(size: fs) 
  L1])
  old.at(0) = old.at(0) + + 6.5*off
  rect(old, (old.at(0) + w_sm, old.at(1) + w_sm/2), fill: mem_color, name: "L13")
  content("L13", [#set text(size: fs) 
  L1])

  let double_arr(name1, name2) = {
    line(name1, name2, mark: (
      start: ">",
      end: ">",
      scale: .75,
      fill: black
    ), 
    )
  }

  double_arr("L11", "SM1")
  double_arr("L12", "SM2")
  double_arr("L13", "SM3")

  let sm_bottom = (off + w_sm/2, 3*off+2*w_sm)
  double_arr("SM1", sm_bottom)
  sm_bottom.at(0) += off + w_sm
  double_arr("SM2", sm_bottom)
  sm_bottom.at(0) += off * 6.5
  double_arr("SM3", sm_bottom)

  double_arr("DRAM","L2")

  content((w/2, w + 1.5), [
    #set text(size: 20pt)
    *GPU*
  ])

  //grid((0,0), (w, w), help-lines: true)
})),
caption : [Simplified architecture of a Graphics Processing Unit]
)<gpu_arch>

#show table.cell.where(y: 0): strong
#set table(
  // stroke: (x, y) => if y == 0 {
  //   (bottom: 0.7pt + black)
  // },
  align: (x, y) => (
    if x > 0 { center + horizon }
    else { left }
  )
)

#figure(
  table(
    columns: 11,
    table.header(
      [CC],
      [5.0, 5.2],
      [5.3],
      [6.0],
      [6.1],
      [6.2],
      [7.x],
      [8.0],
      [8.6],
      [8.9],
      [9.0]
    ),
    [32-bit (single precision)],
    table.cell(colspan: 2)[128],
    [64],
    table.cell(colspan: 2)[128],
    table.cell(colspan: 2)[64],
    table.cell(colspan: 3)[128],
    [64-bit (double precision)],
    table.cell(colspan: 2)[4],
    [32],
    table.cell(colspan:2)[4],
    [32], [32],
    table.cell(colspan: 2)[2],
    [64]
  )
    ,
  caption: [Floating-point add, multiply, multiply-add per clock cyle per SM]
)<TableArithmetic>