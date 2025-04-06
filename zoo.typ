At the time of the previous study @Gamba, the options for porting existing C++ code to a GPU-capable implementation were quite limited and often hardware-dependent. The most popular among them is the Compute Unified Device Architecture (CUDA) @CUDA, a proprietary framework developed by NVIDIA that supports only its GPUs. 
As a strategic response, AMD developed HIP @HIP, a C++ runtime API that allows developers to write code compilable for both AMD and NVIDIA GPUs. Its syntax is intentionally close to CUDA#footnote[Mainly, replacing `cuda` prefixes with `hip`.] to ease code conversion#footnote[AMD also provides an automation tool called `hipify`.] from CUDA to HIP.
Originally, OpenCL @OpenCL was the primary method for GPGPU on AMD and Intel hardware. It is a cross-platform parallel programming standard compatible with various accelerators, including NVIDIA, AMD, and Intel GPUs. However, it is less popular in the scientific community due to limited performance portability @Henriksen and lower productivity, requiring more code to achieve the same results @Martineau.

Additionally, the OpenACC @OpenACC programming standard uses directives for NVIDIA/AMD GPU offloading, making it the GPGPU equivalent of OpenMP. This approach is well-suited for inexperienced developers @Czarnul. More recently, OpenMP introduced GPU offloading via compiler macros, but its performance remains slower than OpenACC @Usha, @ZHANG.

During the past decades, NVIDIA was the uncontested leader in the consumer GPU and HPC markets. Nowadays, AMD and Intel have become serious competitors @Wang. For example, many new HPC infrastructures use non-NVIDIA hardware, such as the European LUMI supercomputer with AMD Instinct GPUs @LUMI. Meanwhile, Intel has launched its Arc GPUs, increasingly featured in mainstream laptops.

Facing increasing heterogeneity in computing platforms, the HPC community has developed high-level abstraction libraries such as Kokkos @Kokkos, RAJA @Raja, SYCL @Sycl, and Alpaka @Alpaka. These are built on traditional GPGPU languages like CUDA, HIP, and OpenCL, allowing users to avoid hardware-specific details by handling backend code within the libraries. This enables developers to write self-contained C++ programs, unlike CUDA and OpenCL, which separate host and device code. The key advantage is a single source file supporting multiple backend targets, including serial and OpenMP-based CPU versions, while ensuring minimal overhead and performance portability. Additionally, these implementations are future-proof, as maintainers can adapt the libraries to emerging hardware like FPGAs or DSPs without requiring major user code rewrites. Notably, Kokkos documentation indicates ongoing backend development.

The latest SYCL standard, SYCL 2020 @SYCL2020, was developed by Khronos, the group behind OpenCL. Various implementations support SYCL 2020 specification to different extents, using different compilers and backends. Notable examples include DPC++ @DPCPP (Intel), ComputeCpp @ComputeCPP (Codeplay), triSYCL @triSYCL, AdaptiveCpp (formerly hipSYCL) @hipSYCL, and neoSYCL @neoSYCL, each targeting different hardware platforms. Note that SYCL can also serve as a backend for both Kokkos @KoSYCL and RAJA @RaSYCL.

A visual summary of the approaches discussed above is presented in @Parallel.

#import "@preview/fletcher:0.5.2" as fletcher: diagram, node, edge
#import fletcher.shapes: house, hexagon, pill, chevron, rect, diamond

#let blob(pos, label, tint: white, ..args) = node(
	pos, align(center, label),
	width: 28mm,
	fill: tint.lighten(60%),
	stroke: 1pt + tint.darken(20%),
	corner-radius: 5pt,
	..args,
)

#let large_blob(pos, label, tint: white, ..args) = node(
	pos, align(center, label),
	width: 40mm,
	fill: tint.lighten(60%),
	stroke: 1pt + tint.darken(20%),
	corner-radius: 5pt,
	..args,
)

#figure(placement: auto,
diagram(
	spacing: 8pt,
	cell-size: (8mm, 10mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
  debug: 0,

	// blob((0,1), [Add & Norm], tint: yellow, shape: hexagon),
	// edge(),
	// blob((0,2), [Multi-Head\ Attention], tint: orange),
	// blob((0,4), [Input], shape: house.with(angle: 30deg),
	// 	width: auto, tint: red),

	// for x in (-.3, -.1, +.1, +.3) {
	// 	edge((0,2.8), (x,2.8), (x,2), "-|>")
	// },
	// edge((0,2.8), (0,4)),

	// edge((0,3), "l,uu,r", "--|>"),
	// edge((0,1), (0, 0.35), "r", (1,3), "r,u", "-|>"),
	// edge((1,2), "d,rr,uu,l", "--|>"),

	// blob((2,0), [Softmax], tint: green),
	// edge("<|-"),
	// blob((2,1), [Add & Norm], tint: yellow, shape: hexagon),
	// edge(),
	// blob((2,2), [Feed\ Forward], tint: blue),

  blob((2.5,0), [Hardware], tint: red, name: <hw>),
  blob((.5,1), [Multicore CPU], tint : orange, shape:hexagon, name: <cpu>),
  edge(<hw>, <cpu>, "-|>", corner: left),
  blob((4.5,1), [GPU], tint : orange, shape:hexagon, name: <gpu>),
  edge(<hw>, <gpu>, "-|>", corner: right),
  blob((.5, 2.25), [Memory \ Access], tint: gray, name: <mem>),
  edge(<cpu>, <mem>, "-|>"),
  blob((-.75, 3.5), [Shared], tint: green, name: <shared>),
  blob((1.75, 3.5), [Distributed], tint: green, name: <distributed>),
  edge(<mem>, <shared>, "-|>", corner: left),
  edge(<mem>, <distributed>, "-|>", corner: right),
  blob((-.75, 4.75), [threads, OpenMP], tint: blue, shape: hexagon, name: <openmp>),
  edge(<shared>, <openmp>, "--|>"),
  blob((1.75, 4.75), [MPI], tint: blue, shape: hexagon, name: <mpi>),
  edge(<distributed>, <mpi>, "--|>"),

  large_blob((4.5, 2.25), [General Purpose \ Languages], tint: gray, name: <mem2>),
  edge(<gpu>, <mem2>, "-|>"),
  
  large_blob((4.5, 4.75), [CUDA, HIP, OpenMP, OpenACC, OpenCL, ...], tint: blue, shape: hexagon, name: <cuda>),
  edge(<gpu>, <cuda>, "--|>"),

  edge(<cpu>, <gpu>, "<|..|>"),
  node((2.5, 1.25), align(center, [_data transfer_])),
  

  // blob((4.5, 4), [CUDA], tint: blue, shape: diamond, name: <cuda>),
),
caption: [Visual diagram of discussed approaches]
) <Parallel>


