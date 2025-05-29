The considerable speedups obtained in REF demonstrate that the future of a faster version of the Watlab program lies in exploiting GPU power rather than relying on CPU parallelism, which has been extensively studied in this work and in the previous work by @Gamba. The GPU-capable implementation is still only partially complete, as it does not support sediment transport. Furthermore, the solution we found to remove polymorphism results in highly redundant code.

As future work, we envision a cleaner and more in-depth adaptation of Watlab to make it more GPU-compliant and easier to maintain, as well as the effective implementation and testing of the remaining features not covered by our prototype. Moreover, the low productivity of our implementation stems from the object-oriented architecture of the code.
We advocate for the removal of classes related to interfaces and cells, replacing them with simple vectors. Indeed, we showed in REF that array-based layouts are more efficient, leveraging cache in CPU-based executions and memory coalescence in GPU-based executions.
More generally, REF highlighted that Watlab is a program with low data intensity, and its performance is mainly constrained by memory latencies. Rather than seeking more computational power, as with GPUs, careful attention should be paid to how data is accessed. For instance, in the current implementation, many variables are related to geometry parsing and mesh initialization, but are no longer used after the initialization of interfaces and cells. These variables increase the stride between elements and thus reduce cache efficiency. Our suggestion for a data structure representing interfaces in a future refactored GPU implementation is given by the following pseudocode:
```cpp
#ifdef USE_FLOATS
typedef float real;
#else
typedef double real;
#endif

struct Interfaces {
    int types[M];              // Type identifiers
    MeshNode<real> n[M];       // Normal vectors
    real length[M];            // Lengths
    size_t local_idx_left[M];  // local indices in left cell
    size_t local_idx_right[M]; // local indices in right cell
    size_t cell_idx_left[M];   // left cell indices
    size_t cell_idx_right[M];  // right cell indices
    real *add_params[M];       // additional parameters needed for certain boundary types
}
```
As you may notice, we let the working floating-point precision be decided at compile time#footnote[Additional macros should be defined for math functions that depend on precision, e.g., #show raw: set text(font: "Ubuntu Mono", size: 9.5pt)
  `sinf` and `sin`.] through macros, to benefit from both the single-precision and double-precision versions of the program, as motivated by REF. \
Naturally, the flux computation depends on the interface type, as was handled through runtime polymorphism in the original implementation. With our new data structure, we need to introduce a switch case to handle this, as follows:
```cpp
void computeFluxes(const Interfaces& interfaces, Cells& cells)
{
  for (size_t i = 0; i < N; i++)
  {
    switch (interfaces.types[i]) {
      case 1: // Type 1
        computeFluxesType1(
          interfaces.n[i],
          interfaces.length[i],
          ...
        );
        break;
      case 2: // Type 2
        computeFluxType2(
          interfaces.n[i],
          interfaces.length[i],
          ...
        );
        break;
      ...
    }
  }
}
```
Therefore, if a new interface type needs to be implemented, we only need to implement the corresponding flux function and extend the switch block accordingly, instead of writing a new derived class. In terms of GPU compliance, the main advantages are:

- Easier data transfers: we only need to copy the `Interfaces` structure into device memory, which can be done in a single transaction.

- SoA layout for improved performance.

- `computeFluxes` can be directly called from AdaptiveCpp queued tasks, as data are passed as arguments. The pointers and variables used in kernel code must remain exclusively on the stack, as the device cannot access host memory.

For the sake of objectivity, we also need to cite the potential disadvantages of this approach:

- The SoA layout might not be optimal for CPU-based executions. During flux computation at a given interface, each field except the normal vector is typically accessed only once, one after the other. This memory reordering may reduce spatial locality, although this should be empirically assessed.

- To avoid branch misprediction on the CPU and warp divergence on the GPU, interfaces should be batched by type. This could be easily integrated in the Python preprocessing program. The caveat is that this conflicts with the memory reordering presented in @section_gpu_reordering. Nevertheless, only boundary interfaces would be affected, and REF showed that their impact remains minimal, as inner interfaces dominate in typical meshes.

Similarly, we can remove geometry-related variables in the cell classes and leverage the SoA layout as follows:
```cpp
struct Cells {
    int types[N];                                // Sediment transport or not
    HydraulicVariableSWE<real> U[N];             // Hydraulic variables
    HydraulicVariableSWE<real> Umax[N];          // For the enveloppes
    HydraulicVariableSWE<real> FluxBuffer[N][3]; // To accumulate fluxes
    real friction[N];                            // Manning's roughness coefficient
    real dqsdh[N];                               // Needed by Exner
    real cellarea[N];                            // Cell's area
    real celldx[N];                              // Cell's characteristic length
    real zbmax[N];                               // Maximum bed node elevation
    real add_param[N];                           // zbr, zb or zw needed by   some interface types
}
```
And the update function should be adapted, as before, to handle Exner morphodynamic computations or not with if-else logic.

The previous study by Gamba conducted extensive research on MPI parallel solutions, that is, following the idea of dividing the problem into subproblems solved independently by different computers. This was done notably by finding the best ways to partition the mesh in order to minimize interprocess communication.
In an even more distant future, we could expect to combine their results with our novel GPU implementation to achieve a simultaneous use of multiple GPUs, each working independently on submeshes of a larger scale case study, as demonstrated in @MORALESHERNANDEZ2021105034 or @SALEEM2024106141.

The presented work mainly focused on discrete GPUs, that is, Graphics Processing Units separate from the processor. Many consumer laptops do not feature such graphic cards, depending on the targeted audience to which they are sold. Besides, most laptop processors include an integrated GPU for display output. As AdaptiveCpp features an OpenCL backend, Watlab could theoretically run on these integrated GPUs. Nevertheless, integrated GPUs are less powerful than discrete GPUs, so there is no prior guarantee that it would be beneficial.
