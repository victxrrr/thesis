#import "@preview/glossarium:0.5.2": make-glossary, register-glossary, print-glossary, gls, glspl
// #import "@preview/scholarly-epfl-thesis:0.2.0": template, front-matter, main-matter, back-matter

// #show: template.with(author: "Victor Lepère")

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

= Introduction

hook 
problématique 
exemple parlant de pq on doit accelere

#pagebreak()
= Governing equations
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

#include "section_4/intro_case_studies.typ"

== Toce

#include "section_4/toce.typ"

== Theux

#include "section_4/theux.typ"

== Profiling

#include "section_4/prof.typ"

#pagebreak()
= Implementations on CPU

== What I did first ?

// parler de ce que j'ai fait les premiers mois ?

== Going parallel

#include "section_5/parallel_cpu.typ"

== The precision issue

#include "section_5/nondeterm.typ"

== Scheduling

#include "section_5/scheduling.typ"

== Memory <memory_section>

#include "section_5/memory_cpu.typ" 

== Case studies results

#include "section_5/cpu_case_studies.typ"

= Implementations on GPU

#include "section_6/intro_gpu.typ"

== Hardware

#include "section_6/hardware_gpu.typ"

== CUDA programming model

#include "section_6/software_gpu.typ"

== Proof of Concept

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


#pagebreak()
= Perspectives

#pagebreak()
= Conclusion

#pagebreak()
= Acknowledgements

// #show: back-matter

#pagebreak()
#bibliography("ref.bib", full:false)
