 #import "@preview/fletcher:0.5.2" as fletcher: diagram, node, edge
#import fletcher.shapes: house, hexagon, pill, chevron, rect, diamond
 
 To choose the most appropriate solution for our project, it was necessary to first clearly define the objectives of the future GPU port. The most important are listed below.

#let unbold(it) = text(weight: "thin", it)
/ _#unbold[Portability]_: The Watlab public software is widely used by researchers at UCLouvain and final-year students with various GPUs. It also runs on the university's supercomputing infrastructure, which is heterogeneous and may evolve over time.

/ _#unbold[Simplicity]_: Since most Watlab maintainers are hydraulics experts rather than developers, it is crucial to avoid low-level hardware-specific instructions and maintain a high level of abstraction. This ensures a focus on physical modeling and guarantees modularity for future hydraulic features. Writing the GPU version purely in C++ would further simplify the architecture.

/ _#unbold[Unified source]_: To minimize development effort and errors, we prioritize a single source code that compiles identically for all GPUs. Additionally, we aim to reduce duplication between the CPU and GPU-enabled versions, given that Watlab already includes serial and OpenMP-based parallel implementations.

/ _#unbold[Performance]_: Since our primary goal is accelerating Watlab, we seek a solution with minimal performance overhead.

Given the frameworks presented in the first section, these criteria help narrow down candidates but are insufficient for a final choice. Based on documentation alone, several frameworks meet the requirements, and benchmarks show similar performance between them @Henriksen @LUMI @Breyer @Martineau.  

To gain deeper insight into the development experience and make the appropriate choice, we designed a small _Proof of Concept_ (PoC) to test the frameworks. The PoC is a simplified, mathematically meaningless version of Watlab that approximates its key components. As noted in section REF, the finite volume implementation consists of flux computation at each interface, updating hydraulic variables in each cell, and a minimum reduction to determine the smallest time step (Fig REF).  

In the PoC, only the water height variable and interface fluxes remain. Starting from a random water level distribution, flux computation averages water heights between adjacent cells. The cell update adds a constant of $2 dot 10^(-6)$ to the water height. Finally, a minimum reduction identifies the smallest water height at each time step. Each implementation must allocate and transfer data between host and GPU and retrieve results post-computation. A schema illustrating the PoC is shown in @poc.

#let blob(pos, label, w, tint: white, ..args) = node(
	pos, align(center, label),
	width: w,
	fill: tint.lighten(60%),
	stroke: 1pt + tint.darken(20%),
	corner-radius: 5pt,
	..args,
)

#figure(move(diagram(
	spacing: 8pt,
	cell-size: (8mm, 10mm),
	edge-stroke: 1pt,
	edge-corner-radius: 5pt,
	mark-scale: 70%,
  debug: 0,

  blob((0, -0.25), [*Data transfer* \ Host $arrow$ Device], 40mm, tint: gray, name: <h2d>),

  blob((0, 1.25), [*Flux kernel* \ $F = (h_L + h_R)/2$], 40mm, tint: blue, name: <flux>),

  blob((0, 2.75), [*Update kernel* \ $h = h + 2 dot 10^(-6)$], 40mm, tint: green, name: <update>),

  blob((0, 4.25), [*Min reduction* \ $h_"min" = min_i h_i$], 40mm, tint: red, name: <min>),

  blob((0, 5.75), [*Data transfer* \ Device $arrow$ Host], 40mm, tint: gray, name: <d2h>),

  edge(<h2d>, <flux>, "-|>"),
  edge(<flux>, <update>, "-|>"),
  edge(<update>, <min>, "-|>"),
  edge(<min>, <d2h>, "-|>"),

  edge(<min>,"rr,uuu,ll", "--|>"),
  node((2.75, 2.75), align(center, [for $T$ steps]))

), dx:12%), caption: [_Proof of Concept_ operating diagram], gap: 5mm)<poc>

For the final step, the reduction must be performed in parallel with optimal local memory usage. To achieve this, we use built-in reduction algorithms when available, ensuring they meet these requirements.

The candidate frameworks implemented for the PoC, alongside the serial version, include CUDA, OpenMP (CPU and GPU offloading), OpenACC, Kokkos, RAJA, SYCL, and Alpaka. The OpenMP CPU version is for comparison only. Similarly, while CUDA does not meet our previous criteria, it helps assess the overhead of abstraction libraries compared to native CUDA. OpenCL was excluded due to its incompatibility with simplicity and unified source requirements. OpenACC, primarily supported by NVIDIA, is experimentally available on AMD GPUs via GCC @GCC hence it does not constitute a viable solution. However, given its simple implementation, we included it for a broader comparison.

Attentive readers may wonder which SYCL2020 implementation we used for our PoC. We chose AdaptiveCpp, as it supports CPUs via OpenMP and targets NVIDIA, AMD, and Intel GPUs while delivering competitive performance @sycl_bench @sycl_bench2 @sycl_swe. AdaptiveCpp is also the only implementation that does not rely exclusively on OpenCL but also on native backends (e.g. CUDA and HIP).  It might be beneficial since OpenCL has shown to be less performant than HIP and CUDA on equivalent benchmarks @Henriksen. Finally, the key property that led us to choose AdaptiveCpp is its novel single-source, single-compiler-pass (SSCP) design @SSCP.

Indeed, although several solutions can generate source code compilable for a broad range of architectures, this does not equate to producing a single universal binary that runs on all architectures. For instance, with the CUDA compiler, nvcc must explicitly specify NVIDIA architectures (Turing, Volta, Ampere, etc.) to produce a fat binary compatible with them. However, the resulting executable cannot be used with AMD or Intel GPUs since no unified code representation exists between drivers. The situation is even worse for AMD, as it does not provide a device-independent code representation. Thus, compiling for all AMD GPUs requires separate compilation for each. This limitation also affects higher-level libraries like Kokkos, preventing simultaneous compilation with both CUDA and HIP backends. #footnote[Note, however, that Serial, CPU-parallel (OpenMP), and CUDA/HIP/OpenMP GPU offloading versions can be combined.]

This is where AdaptiveCpp's generic compilation becomes attractive. The SSCP compiler stores an intermediate representation (LLVM IR) at compile time, which is backend- and device-independent. At runtime, the architecture is detected Just-in-Time, and the code is translated accordingly to meet driver expectations. Naturally, this approach introduces a runtime overhead, whose impact will be assessed in the next section.


