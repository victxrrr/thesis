In @Testa2007, the authors described flash flood experiments conducted on a 1:100 scale physical model of the Toce River valley, built in concrete. An urban district made of several concrete block buildings was placed in the riverbed to simulate flooding in a populated area and study the complex flow patterns caused by water interactions. Multiple water depth gauges were installed to collect bathymetric data, and an electric pump controlled the inflow discharge, determining the flood intensity. Together, the topography, inflow, and gauge measurements form a dataset well-suited for validating mathematical flood models.

In our case, we use a mesh file based on this experimental setup, shown in @Toce. 
The inflow enters the domain through the west boundary indicated in the figure and exits through 
a transmissive boundary at the far end. Note the 20 aligned squares representing scaled models of buildings. Sediment transport is not considered in this case study.

#figure(placement: auto,
    box(image("../img/toce.svg"), clip: true, inset: (top: -0pt)),
    caption: [Mesh corresponding to the small-scale model of the Toce River]
)<Toce>

The key properties of the mesh geometry are listed in @meshes. Notice that we generated another mesh, much larger, on the same domain by significantly reducing the mesh size. This results in a mesh with about 800 000 small triangles, which we call Toce _XL_. This geometry will be used in @poc_section, where we only need a large number of cells to leverage GPU computational power for toy examples. However, we will not run Watlab on it, as very small cells may cause inconsistencies. First, due to @CFL, which significantly reduces the acceptable step size. Second, it may lead to arithmetic precision loss because of the difference in order of magnitude between the numerical fluxes, source terms, hydraulic variables, and the geometric quantities related to the cells in @update.

Regarding simulation parameters, the CFL number is set to $sigma = 0.9$, and the simulation runs from time 7 to 60. This choice is based on the boundary hydrograph provided with the dataset (@inflow). We also periodically generate pictures of the hydraulic variables and gauge measurements, with gauge positions matching those in @Testa2007 as described in @simulations. The gauge coordinates are shown in @Toce. We also recorded envelopes every second, which correspond to the maximum values of height and velocities for each computational cell. Finally, we recorded the measurements over the inflow and outflow sections to exploit all output capabilities of the program.

#figure(placement: auto,
    box(image("../img/inflow.svg", width: 70%), clip: true, inset: (top: 0pt)),
    caption: [Inflow hydrograph]
)<inflow>




