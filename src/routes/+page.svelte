<script>
    import Map from "$lib/Map.svelte"
    import Profile from "$lib/Profile.svelte"
    import { Em } from "@onsvisual/svelte-components";
</script>


<h1>Abbott Barton Barn</h1>
<p>The area outlined in blue in the map below shows the area which is closest to the Abbott's Barton barn when considering local shops. The corresponded grey area is the smallest areas which the Office for National Statistics has data for. The areas chosen are the ones where the population weighted centroid falls into the blue area. </p>
<Em color="#22d0b6">Post offices</Em>
<Em color="#27a0cc">Shops</Em>
<Em color="#f66068">Abbott's Barton barn</Em>
<Map/>
<Profile/>