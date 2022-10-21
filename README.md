<h1 align="center">
  GMFlux 1.0.0
</h1>
<p align="center">
  <img src="https://user-images.githubusercontent.com/12619098/197270053-cb102163-895e-40aa-80f8-4e8007af517d.gif">
</p>

## About
GMFlux is a height-field fluid simulation solver written in GML2.3+ and GLSL-ES 1.0

## Contents
GMFlux comes with a packaged `.yyp` consisting of:
- Main solver library `GMFlux/gmflux_lib.gml`
- Adaptive LOD mesh processor `GMFlux/gmflux_mesh.gml`
- GLSL-ES shader backend `GMFlux/glsl-es/`
- Example VTF-based renderer `Example/`
- - !NOTICE! Due to an issue with GM:Studio's sampler bindings, ANGLE doesn't transpile vertex texture fetching operations. Currently the example renderer only works with VTF-supported platforms.

## Instructions
- `git clone` this repo or download from releases.
- Open `GMFlux.yyp` with GM:Studio IDE (2.3+).
- Refer to `Example/Object1` for additional instructions.

<h2 align="center">Features</h2>
<p align="center">Blazingly fast GPU-based height-field fluid solver.</p>
<p align="center">
  <img src="https://user-images.githubusercontent.com/12619098/197278837-1b967714-12d9-48c3-8a0e-116548c4a152.gif">
</p>

<p align="center">Process huge overworld simulations, as well as instanced pools, etc.</p>
<p align="center">
  <img src="https://user-images.githubusercontent.com/12619098/197278491-37e95e5a-1feb-45a7-820a-27182379a309.gif">
</p>

<p align="center">Dynamic manipulation of terrain, depth and flow via render-target approach (akin to `surface_set_target()`)</p>
<p align="center">
  <img src="https://user-images.githubusercontent.com/12619098/197279186-b80c7a58-e41f-4a1f-a137-97e18ad38bb7.gif">
  <img src="https://user-images.githubusercontent.com/12619098/197280227-5009d67f-a2cc-40f9-b5e4-8d9d5244958e.gif">
</p>

<p align="center">Optimized fragment lookups and RGBA decoding allowing the CPU to process physics like buoyancy, flow, etc.</p>
<p align="center">
  <img src="https://user-images.githubusercontent.com/12619098/197280063-bd0bc543-a1b8-4154-94c5-66909dd1ac8b.gif">
</p>

<p align="center">Dynamic ripples, waves, foam, wet surfaces, rain, caustics and fresnel reflections</p>
<p align="center">Customizable color, opacity, reflection, fade, fall-off </p>
<p align="center">
  <img src="https://user-images.githubusercontent.com/12619098/197280439-c677bd26-554b-4521-88ef-8df10f576471.gif">
  <img src="https://user-images.githubusercontent.com/12619098/197281021-bceccbe2-240e-4b41-ae1f-281ac1c9c794.gif">
</p>

## Todo
- Desktop VTF extension
- Switch the `FluxCell.FluxLD` and `FluxCell.FluxRU` encoding to each handle one dimension (sample same index for each dimension instead of this multi-sampled horror)
- Projected instead of embedded caustics
- Implement optional, even more detailed inter-cardinal flux
- Multi-pass the flux step if possible (less total samples)

### Credits:
- @XorDev : Non-cubemap skybox sampling method
- polyhaven.com : Skybox image
