#import "@preview/scholarly-epfl-thesis:0.2.0": template, front-matter, main-matter, back-matter

#show: template.with(author: "Your name")

// #set pagebreak(weak: true)
#set page(numbering: none)


#show: front-matter

#outline(title: "Contents")
#outline(title: "List of Figures", target: figure.where(kind: image))
#outline(title: "List of Tables", target: figure.where(kind: table))
// #outline(title: "List of Listings", target: figure.where(kind: raw))

#show: main-matter

#show: back-matter
