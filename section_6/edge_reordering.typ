To maximize coalesced memory access, neighboring threads should access neighboring entries in the cell and interface arrays. 
In our parallel implementation, this applies primarily to the flux kernel, where each interface reads water heights from adjacent cells. 
As discussed in @memory_section, applying the Reverse Cuthill-McKee algorithm to 
renumber cell indices brings neighboring cells closer in memory, improving per-thread coalescence. 
Sorting interfaces based on these new indices further enhances coalescence at the warp level, allowing threads to reuse 
loaded data or access nearby values. A visualization of these accesses is shown in @mem_coalescence.

#import "@preview/cetz:0.3.4": canvas, draw, decorations
#import draw: rect, content, line, grid, mark, circle
#figure(
    gap: 5pt,
    placement: auto,
    scale(90%, 
    canvas({
      
      let sm_color = teal.lighten(30%)
      let mem_color = red.lighten(10%)
      let core_color = green
      let chip_color = gray.lighten(80%)
      let chip_edge = gray.lighten(0%)
    
      let w = 8
      let w_thread = (1/3) * .8
      let inset = .15 * 1
    
      let mask = (14, 15, 16)
    
      let off = 0
    
      let row(y_off, mask) =  {
        /*let inset = 0
          
        for i in range(0, 32) {
          if i not in mask {
            rect(
            (inset + i * (w_thread + inset), y_off), (inset + i * (w_thread + inset) + w_thread, w_thread + y_off), 
              fill: core_color.lighten(80%), stroke: gray.lighten(20%)
            )
          }
        }
        for i in range(0, 32) {
            if i in mask {
              rect(
                (inset + i * (w_thread + inset), y_off), (inset + i * (w_thread + inset) + w_thread, w_thread + y_off), 
                fill: core_color, name: "core" + str(i)
              )
            } 
          }
        for i in (1, 8, 16, 24, 32) {
            content((inset + w_thread/2 + (i -1) * (w_thread + inset), y_off - .25),  [#i])
          }*/
        
          let dx = .75
          for i in mask {
            rect(
              ((i+1) * (w_thread) + (i - 15) * dx, y_off), ((i+1) * (w_thread) + w_thread + (i - 15) * dx, w_thread + y_off), 
              fill: core_color, name: "core" + str(i)
            )
            // content((i * (w_thread) + (i - 15) * dx + w_thread/2, y_off - .25),  [#i])
          } 
      }

      let array(y_off, mask) =  {
        let outset = .15
        let dash_len = .66
        for i in (0, 1) {
            line((-outset + 2*w_thread, y_off + i*w_thread), (30 * (w_thread) + outset, y_off + i*w_thread))
            line((30 * (w_thread) + outset, y_off + i*w_thread), (30 * (w_thread) + outset + dash_len, y_off + i*w_thread),
                stroke: (dash: "dashed"))
            line((-outset + 2*w_thread, y_off + i*w_thread), (-outset - dash_len + 2*w_thread, y_off + i*w_thread), stroke: (dash: "dashed"))
        }

        for i in range(0, 32) {
            if i in mask {
                rect(
                  (i * (w_thread), y_off), (i * (w_thread) + w_thread, w_thread + y_off), 
                  fill: mem_color, name: "mem" + str(i)
                )
              } 
        }

      }

      let line-style = (stroke: .75pt)

      let gap = 1.5

      array(gap, (4, 5, 6, 25, 26, 27))
      row(0, mask)
      line("core14.north", "mem4.south", ..line-style)
      line("core14.north", "mem25.south", ..line-style)
      line("core15.north", "mem5.south", ..line-style)
      line("core15.north", "mem26.south", ..line-style)
      line("core16.north", "mem6.south", ..line-style)
      line("core16.north", "mem27.south", ..line-style)

      content(( 36 * w_thread, gap + w_thread * .66), [_cells_])
      content(( 25 * w_thread, w_thread * .66), [_threads_])

      content(( -7 * w_thread, gap/3 + w_thread * .66), [*Original*])

      let dy = -2.5
      array(gap  +dy, (5, 6, 15, 16, 25, 26))
      row(0+ dy, mask)
      line("core14.north", "mem5.south", ..line-style)
      line("core14.north", "mem6.south", ..line-style)
      line("core15.north", "mem15.south", ..line-style)
      line("core15.north", "mem16.south", ..line-style)
      line("core16.north", "mem25.south", ..line-style)
      line("core16.north", "mem26.south", ..line-style)

      content(( -7 * w_thread, dy + gap/3 + w_thread * .66), [*RCM*])

      dy = dy + dy
      array(gap  +dy, (13, 14, 15, 17, 18, 19))
      row(0+ dy, mask)
      line("core14.north", "mem13.south", ..line-style)
      line("core14.north", "mem17.south", ..line-style)
      line("core15.north", "mem14.south", ..line-style)
      line("core15.north", "mem18.south", ..line-style)
      line("core16.north", "mem15.south", ..line-style)
      line("core16.north", "mem19.south", ..line-style)

      content(( -7 * w_thread, dy + gap/3 + w_thread * .66), [*RCM + Sort*])
    
      //grid((0,0), (w, w), help-lines: true)
    })),
    caption : [Idealized memory accesses in the flux kernel to retrieve $h_L$ and $h_R$]
    )<mem_coalescence>

Coalesced memory is not the only benefit of mesh reordering. While clearly visible in the Proof of Concept due to its simplicity, it also reduces warp divergence. In Watlab, flux computations and cell updates vary when cell water heights fall below a user-defined threshold. These cells are considered dry, and no flux is computed between two dry cells. \
Physically, water tends to form a contiguous wet zone as it propagates, with only the moving front expanding. This makes it likely that dry cells are surrounded by other dry cells, and similarly for wet cells, except near the wet-dry boundary. The RCM algorithm renumbers cells so that neighboring cells have nearby indices. Sorting interfaces by their left and right cells ensures that neighboring interfaces also have close indices. \
As seen in @after_reordering, cell indices increase from the top-right to the bottom-left corner, and so do interface indices. This means contiguous threads in a warp are more likely to process cells in the same state—either wet or dry—leading to more uniform execution paths. Threads handling the moving front are the main exceptions.

The reasoning can be extended to boundary interfaces, which differ from inner ones as they have no right-side cells. Their flux computations are either simplified or follow hydrograph or limnigraph inputs. Since boundary conditions are applied uniformly across domain edges, which the mesh generator segments into similar interfaces, a good strategy is to start renumbering boundary edges in a counterclockwise order. This reduces warp divergence near domain edges. \
GMSH already follows this approach, as seen in @square_mesh.

We tested these strategies on the same test case as above to evaluate their effectiveness using the AdaptiveCpp implementation. The results are reported in @poc_rcm and @rcm_ker.

#show table.cell.where(y: 0): strong
#set table(
  stroke: (x, y) => if y == 0 {
    (bottom: 0.7pt + black)
  },
  align: (x, y) => (
    if x > 0 { center + horizon }
    else { left }
  )
)

#import "@preview/fancy-units:0.1.1": unit, qty
#import "@preview/subpar:0.2.2"

#subpar.grid(
  figure(table(
  columns: (40%, 30%, 30%),
  table.header(
    [Reordering],
    [Duration [#unit[s]]],
    [Speedup vs serial],
  ),
  [RCM + Sort], [$1.84 thick (plus.minus 0.04)$], [30.52],
  [RCM + Sort with boundary variant], [$1.84 thick (plus.minus 0.04)$], [30.54],
), gap: .75em, caption: [Total execution times]),
<poc_rcm>,
  figure(table(
    columns: (16%, 21%, 31.5%, 31.5%),
    table.header(
      [Reordering],
      [Duration [#unit[ms]]],
      [Compute Throughput [#unit[%]]],
      [Memory Throughput [#unit[%]]],
    ),
    [RCM + Sort], [$0.90 thick (plus.minus 0.003)$], [$4.33 thick (plus.minus 0.015)$], [$63.93 thick (plus.minus 0.214)$],
    [Variant], [$0.90 thick (plus.minus 0.003)$], [$4.32 thick (plus.minus 0.014)$], [$63.90 thick (plus.minus 0.210)$], 
  ), gap: .75em, caption: [Flux kernel profiling]),
  <rcm_ker>,
  figure(table(
    columns: (16%, 21%, 31.5%, 31.5%),
    table.header(
      [Reordering],
      [Duration [#unit[ms]]],
      [Compute Throughput [#unit[%]]],
      [Memory Throughput [#unit[%]]],
    ),
    [RCM + Sort], [$0.29 thick (plus.minus 0.004)$], [$4.51 thick (plus.minus 0.053)$], [$86.68 thick (plus.minus 0.487)$], 
    [Variant], [$0.29 thick (plus.minus 0.004)$], [$4.52 thick (plus.minus 0.056)$], [$86.62 thick (plus.minus 0.500)$], 
  ), gap: .75em, caption: [Update kernel profiling]),
  figure(table(
    columns: (16%, 21%, 31.5%, 31.5%),
    table.header(
      [Reordering],
      [Duration [#unit[ms]]],
      [Compute Throughput [#unit[%]]],
      [Memory Throughput [#unit[%]]],
    ),
    [RCM + Sort], [$0.15 thick (plus.minus 0.000)$], [$9.42 thick (plus.minus 0.025)$], [$95.32 thick (plus.minus 0.214)$],
    [Variant], [$0.15 thick (plus.minus 0.000)$], [$9.42 thick (plus.minus 0.025)$], [$95.29 thick (plus.minus 0.183)$], 
  ),  gap: .75em, caption: [Min reduction profiling]),
  columns: 1,
  caption: [Timings of AdaptiveCpp implementation with reordered mesh (Toce _XL_)],
  kind: table,
  //label: <ncu>
  numbering: n => {
    let h1 = counter(heading).get().first()
    numbering("1.1", h1, n)
  }, gap: 1em
)

We observe that the new reordering effectively reduces the execution time and the speedup factor increases from $~24$ to $~30.5$. Kernel profiling shows an increase in memory throughput, indicating an improvement in memory coalescence, that results in a decrease in the execution time. However, the boundary variant does not improve performance. We justify this by noting that warp divergence is not very pronounced in the PoC: boundary edges simply skip the mean water height computation, but as shown by kernel profiling, the limiting factor is memory access rather than computational load. Moreover, the reordering variant, while reducing warp divergence, also reduces spatial locality because the indices of the cells sharing a boundary interface are not direct neighbors except at corners. Finally, the number of boundary interfaces remains negligible compared to the number of inner interfaces in a large mesh as used in the test case.

