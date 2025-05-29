#import "template.typ": template, front-matter, main-matter, back-matter

#show: template.with(author: "Victor Lepère")

// #set page(numbering: none)
#show: front-matter

#set par(
  first-line-indent: 1em,
  justify: true,
)

#set math.vec(delim: "[")
#set math.mat(delim: "[")

#outline()
// #pagebreak()
#outline(title: "Figures", target: figure.where(kind: image))

#outline(title: "Tables", target: figure.where(kind: table))

= Abbreviations

#align(center)[
#grid(
  columns: (15%, 60%),
  align(left)[#set text(weight: "regular")
    #set par(leading: 1em)
    SWE \
    HLLC \
    CFL \
    GPU \
    CPU \
    OpenMP \
    API \
    MPI \
    SM \
    SIMT \
    GPGPU \
    CUDA \
    AMD \
    HIP \
    OpenCL \
    OpenACC \
    HPC \
    LUMI \
    SYCL \
    FPGA \
    NPU \
    DPC++ \
    OpenGL \
    CC \
    VRAM \
    PCIe \
    DMA \
    PoC \
    JIT \
    RCM \
    AoS \
    SoA \
    AoSoA \
    FP32 \
    FP64 \
    USM \
    IR \
    FMA \
  ],
  align(left)[#set par(leading: 1em)
    Shallow water equations \
    Harten-Lax-van Leer-Contact \
    Courant-Friedrichs-Lewy \
    Graphics Processing Unit \
    Central Processing Unit \
    Open Multi-Processing \
    Application Programming Interface \
    Message Passing Interface \
    Streaming Multiprocessor \
    Single Instruction, Multiple Threads \
    General-Purpose computing on GPUs \
    Compute Unified Device Architecture \
    Advanced Micro Devices \
    Heterogeneous-computing Interface for Portability \
    Open Computing Language \
    Open Accelerators \
    High Performance Computing \
    Large Unified Modern Infrastructure \
    SYstem-wide Compute Language \
    Field-Programmable Gate Array \
    Neural Processing Unit \
    Data Parallel C++ \
    Open Graphics Library \
    Compute Capability \
    Video Random Access Memory \
    Peripheral Component Interconnect Express \
    Direct Memory Access \
    Proof of Concept \
    Just-In-Time \
    Reverse Cuthill-McKee \
    Array of Structures \
    Structure of Arrays \
    Array of Structures of Arrays \
    Single-precision floating-point format \
    Double-precision floating-point format \
    Unified Shared Memory \
    Intermediate Representation \
    Fused Multiply-Add \
  ]
)
]

#show: main-matter

#import "@preview/suboutline:0.3.0": suboutline
#let minioutline() = {
  line(length: 100%)
  v(1%)
  suboutline(fill: repeat([#h(2.5pt) . #h(2.5pt)]))
  line(length: 100%)
}

#show: main-matter
= Introduction
#include "section_1/intro.typ"

= Governing equations <ch2>
#minioutline()

== Shallow water equations

#include "section_2/SWE.typ"

== Numerical scheme

#include "section_2/FV.typ"

== Data parallelism

#include "section_2/data_parallelism.typ"

== Program structure <structure_section>

#include "section_2/program_struct.typ"

// #pagebreak()
= State of the art <ch3>
#minioutline()

== Parallelization methods

#include "section_3/parallel_methods.typ"

== Graphics Processing Units

#include "section_3/state_gpu.typ"

== The zoo of GPGPU languages

#include "section_3/zoo.typ"

== Trends in SWE solvers

#include "section_3/trends_swe.typ"

// #pagebreak()
= Case studies <ch4>
#minioutline()

#include "section_4/intro_case_studies.typ"

== Toce

#include "section_4/toce.typ"

== A square basin

#include "section_4/basin.typ"

// #pagebreak()
= Implementations on CPU <ch5>
#minioutline()

#include "section_5/intro.typ"

== Toce river: Profiling

#include "section_5/prof.typ"

== Going parallel <parallel_section>

#include "section_5/parallel_cpu.typ"

== The precision issue <precision_section>

#include "section_5/nondeterm.typ"

== Scheduling

#include "section_5/scheduling.typ"

== Memory <memory_section>

#include "section_5/memory_cpu.typ"

== Benchmarks

#include "section_5/cpu_case_studies.typ"

= Implementations on GPU <ch6>
#minioutline()

#include "section_6/intro_gpu.typ"

== Hardware

#include "section_6/hardware_gpu.typ"

== CUDA programming model

#include "section_6/software_gpu.typ"

== Proof of Concept <poc_section>

#include "section_6/poc.typ"

=== Results

#include "section_6/poc_results.typ"

=== Optimizations

#include "section_6/intro_opti.typ"

==== Mesh reordering <section_gpu_reordering>

#include "section_6/edge_reordering.typ"

==== Data layout

#include "section_6/soa.typ"

==== Arithmetic precision

#include "section_6/floats.typ"

== GPU port of Watlab

=== Program structure

#include "section_6/gpu_port.typ"

=== Polymorphism challenges <section_poly>

#include "section_6/poly.typ"

=== Managing data transfers

#include "section_6/usm.typ"

=== CPU-GPU synchronization

#include "section_6/sync.typ"

=== Analysis & benchmarks

#include "section_6/bench.typ"

// #pagebreak()
= Perspectives <ch7>

#include "section_7/perspectives.typ"

// #pagebreak()
= Conclusion
#include "section_8/conclusion.typ"

#show: back-matter
// #pagebreak()
#bibliography("ref.bib", full:false)
Finally, generative artificial intelligence through ChatGPT and DeepL Write was used as a language assistant to review the spelling and grammar of the manuscript.
