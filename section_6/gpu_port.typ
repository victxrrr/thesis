#import "@preview/fletcher:0.5.3" as fletcher: diagram, node, edge

#let light_blob(pos, label, w, tint: white, ..args) = node(
	pos, align(center, label),
	width: w,
	fill: tint.lighten(90%),
	stroke: 1pt + tint.lighten(30%),
	corner-radius: 5pt,
	..args,
)

#let blob(pos, label, w: auto, tint: white, ..args) = node(
	pos, align(center, label),
	width: w,
	fill: tint.lighten(70%),
	stroke: 1pt + tint.darken(20%),
	corner-radius: 5pt,
	..args,
)

#let scale_width(canvas) = {
  context {
    let canvas-size = measure(canvas)
    layout(size => {
      let width = canvas-size.width
      let width = size.width
      scale(width/canvas-size.width * 100%, canvas)
    })  
  }
}

The significant speedups achieved with the GPU port of the proof of concept motivate us to port the full Watlab version as well. Its architecture is similar to the parallel implementation described in @parallel_section. The main difference is that it uses two independent chips that run separately. The GPU handles the computations of the three loops in @hydroflow as well as the minimum reduction, while the CPU writes output data to files. To do this, cell arrays are transferred back from the GPU when it is time to output. The caveat of using two independent hardware units is the need to transfer shared data between them. In a sense, this can be seen as an instance of task parallelism under the distributed memory paradigm. At each iteration, we also need to transfer the computed time step since the global logic is managed by the processor. The resulting program structure is shown in @hydroflow_gpu.

#figure(placement: auto, scale_width(diagram(
	spacing: 8pt,
	cell-size: (8mm, 10mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
  debug: 0,

  let pos = 0,
  let dy = 1.25,
  let gpu_dx = .95,
  let output_dx= -2.75,
  let kernel_off= -0.045,
  let side_dy = 2,
  blob((0, pos - 2.3*dy), [Initialization], tint: gray, name: <h2d>),
  edge("-|>"),
  blob((0, pos - 1.15*dy), [*Data transfer* \ CPU #sym.arrow.r GPU]),
  edge("-|>"),
  blob((0, pos), [Time to output ?], tint: gray, name: <if>),


  let side = pos,
  side += side_dy,
  blob((output_dx, side), [Has previous \ output finished ?], tint: gray, name: <yes>),
  edge(<yes.south-east>, "-|>", <yes.north-east>, [no],  bend: -125deg, label-pos: .6),
  side += 1.25*dy,
  edge("-|>"),
  blob((output_dx, side), [*Data transfer* \ CPU #sym.arrow.l GPU], name: <save>),
  side += dy,
  edge("-|>"),
  blob((output_dx, side), [Write data], tint: green, name: <write>),
  
  pos += dy,
  blob((gpu_dx, pos), [$bold(F)_j^*$ #h(.5em) *for each* interface ], tint: blue, name: <flux>),
  edge((kernel_off, pos), <flux.west>, "@-|>", label: [], label-pos: .3),

  pos +=  dy,
  blob((gpu_dx, pos), [$bold(S)_i^*$ #h(.5em) *for each* cell], tint: blue, name: <source>),
  edge((kernel_off, pos), <source.west>, "@-|>", label: [_kernel_], label-pos: .6),

  pos += 1*dy,
  blob((0, pos), [Has data \ been transferred ?], tint: gray, name: <sync>),
  edge(<sync.south-west>, "-|>", <sync.north-west>, [no],  bend: 125deg, label-pos: .7),

  pos += 1.1*dy,
  blob((gpu_dx, pos), [$bold(U)_i^(n+1) = bold(U)_i^n  - (Delta t \/ abs(cal(C)_i)) sum_(j) bold(T)^(-1)_j bold(F)^*_j  L_j \ + bold(S)_i^* Delta t #h(1em) #text([*for each* cell])$], tint: blue, height: 18mm, name: <update>),
  edge((kernel_off, pos), <update.west>, "@-|>", label: []),

  pos += 1.15*dy,
  blob((gpu_dx, pos), [$Delta t = min_i ( (Delta x)/(abs(u) + c) )_i$], height: 9mm, tint: red, name: <min>),
  edge((kernel_off, pos), <min.west>, "@-|>", label: []),

  pos += dy,
  blob((0, pos), [*Data transfer* \ CPU #sym.arrow.l GPU], name: <min2h>),
  pos += dy*1.25,
  edge("-|>", [$t = t + sigma Delta t$], label-side: left),
  blob((0, pos), [$t >= t_"end"$ ?], tint: gray, name: <d2h>),
  pos += dy,
  edge("-|>", [yes], label-side: left),
  blob((0, pos), [Termination], tint: gray),
  edge(<if>, "-|>", <sync>),
  edge(<sync>, "-|>", <min2h>, label: "yes", label-side: left, label-pos: .145),

  // edge(<h2d>, <if>, "-|>"),
  // edge(<flux>, (0., 2.85), "-|>"),
  // edge(<update>, <buf>, "-|>"),
  // edge(<min>, (0, 7.65), "-|>"),
  // // edge(<if>, (0, .8+.45), "-|>", label: [no], label-side: left),
  edge((<if.south>, 50%, <if.south-west>), (rel: (0, side_dy/3)), (rel: (output_dx*.885, 0)), (rel: (0, side_dy/2)), "..|>", label: "yes"),
  // node((-0.5, -.25), align(center, [yes])),
  //node((0.075, .5), align(center, [no])),

  //edge(<d2h>,"rr,uuuuuuuuuuu,ll","--|>", label: "no"),
  edge(<d2h>, (rel: (-3.75, 0)), (rel: (0, -9.375)), "rrrr","--|>", label: "no", label-side: right, label-pos: .166),
  // edge(<red>, <d2h>, "-|>", label: [$t = t + sigma Delta t$], label-side: left),

  // edge(<buf>, (0, 5.85), "-|>", label: [yes], label-side: left),
  // 

  let off = .4,
  edge(<write.south>, (output_dx, 4.4 + off), "-"),
  edge((output_dx, 4.4 + off), (output_dx, 5 + off), "--"),

  node(enclose: (<min>, <update>, <flux>), inset: 10pt, stroke: (paint: gray, dash: "dashed"), fill: none, corner-radius: 10pt),
  node((gpu_dx, 3.75), align(center, text(size: 17pt, fill: luma(30%), [_GPU_])))
)), caption: [Updated program structure of the parallel implementation]) <hydroflow_gpu>
