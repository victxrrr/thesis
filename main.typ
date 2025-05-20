#import "@preview/glossarium:0.5.2": make-glossary, register-glossary, print-glossary, gls, glspl
#import "template.typ": template, front-matter, main-matter, back-matter

#show: template.with(author: "Victor Lepère")

// #set page(numbering: none)
// #show: front-matter

#counter(page).update(n => n + 0)

#set text(11pt, lang: "en")
#set align(left)
//#set page(numbering: "— 1 —")
#set page(numbering: "1")
#set heading(numbering: "1.1.1")
#set par(
  first-line-indent: 1em,
  justify: true,
)
#set figure.caption(separator: " - ")
#set figure(gap: 5mm)
//#set math.equation(numbering: it => emph[#numbering("(i)", it)])
// #let numbered_eq(content) = math.equation(
//     block: true,
//     numbering: it => emph[#numbering("(i)", it)],
//     content,
// )

//#set figure(numbering: it => emph[#numbering("(i)", it)])

#set math.equation(numbering: "(1)")

#import "@preview/fancy-units:0.1.1": unit

#set math.vec(delim: "[")
#set math.mat(delim: "[")

#outline()
#pagebreak()
#outline(title: "Figures", target: figure.where(kind: image))

#outline(title: "Tables", target: figure.where(kind: table))

#pagebreak()

#show: make-glossary
#let entry-list = (
  (
    key: "kul",
    short: "KUL",
    long: "Katholieke Universiteit Leuven",
    description: "A university in Belgium.",
  ),
  // Add more terms
)
#register-glossary(entry-list)

// #print-glossary(
//  entry-list, show-all: true
// )
//

// #show: main-matter

#import "@preview/suboutline:0.3.0": suboutline
// #show heading: set text(11pt, weight: "regular")
// #show heading.where(level: 1): it => {
//   {
//     set align(right)
//     set par(spacing: 5mm)
//     let number = counter(heading.where(level: 1)).display()
//     text(90pt, rgb("#cd5454"), strong(number))
//     parbreak()
//     text(20pt, it.body)
//   }
//   line(length: 100%)
//   show outline.entry: it => {
//     let body = {
//       box(stroke: red, outset: 1pt)[#it.prefix()#h(1.5em)#it.body()]
//       h(4mm)
//       box(width: 1fr, it.fill)
//       h(7mm)
//       it.page()
//     }
//     pad(left: 1.5cm, right: 1cm, link(it.element.location(), body))
//   }
//   suboutline(fill: repeat(gap: 0.5em)[.])
//   line(length: 100%)
// }
//
#let minioutline() = {
  line(length: 100%)
  v(1%)
  suboutline(fill: repeat([#h(2.5pt) . #h(2.5pt)]))
  line(length: 100%)
}

= Introduction

hook
problématique
exemple parlant de pq on doit accelere

#pagebreak()
= Governing equations <ch2>
#minioutline()

== Shallow water equations

#include "section_2/SWE.typ"

== Numerical scheme

#include "section_2/FV.typ"

== Data parallelism

#include "section_2/data_parallelism.typ"

== Program structure

#include "section_2/program_struct.typ"

#pagebreak()
= State of the art
#minioutline()

== Parallelization methods

#include "section_3/parallel_methods.typ"

== Graphics Processing Units

#include "section_3/state_gpu.typ"

== The zoo of GPGPU languages

#include "section_3/zoo.typ"

== Trends in SWE solvers

#include "section_3/trends_swe.typ"

#pagebreak()
= Case studies
#minioutline()

#include "section_4/intro_case_studies.typ"

== Toce

#include "section_4/toce.typ"

== A square basin

#include "section_4/basin.typ"

#pagebreak()
= Implementations on CPU
#minioutline()

#include "section_5/intro.typ"

== Profiling of Toce case study

#include "section_5/prof.typ"

== Going parallel <parallel_section>

#include "section_5/parallel_cpu.typ"

== The precision issue

#include "section_5/nondeterm.typ"

== Scheduling

#include "section_5/scheduling.typ"

== Memory <memory_section>

#include "section_5/memory_cpu.typ"

== Benchmarks

#include "section_5/cpu_case_studies.typ"

= Implementations on GPU
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

==== Mesh reordering

#include "section_6/edge_reordering.typ"

==== Data layout

#include "section_6/soa.typ"

==== Arithmetic precision

#include "section_6/floats.typ"

== GPU port of Watlab

=== Program structure

#include "section_6/gpu_port.typ"

=== Polymorphism challenges

#include "section_6/poly.typ"

=== Managing data transfers

#include "section_6/usm.typ"

=== CPU-GPU synchronization

#include "section_6/sync.typ"

=== Benchmarks

#include "section_6/bench.typ"

#pagebreak()
= Perspectives

#pagebreak()
= Conclusion

#pagebreak()
= Acknowledgements

// #show: back-matter
#pagebreak()
#bibliography("ref.bib", full:false)
