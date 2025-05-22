<script>

import {Map, MapSource, MapLayer, MapTooltip} from '@onsvisual/svelte-maps';
import { getData, getColor, getTopo } from "$lib/js/utils.js";
import shopVoronoi from "$lib/data/proposed_location_shop_voronoi.json"
import points from "$lib/data/all_facilities.json"

const oaBoundaries = {
    url: "https://cdn.ons.gov.uk/maptiles/administrative/2021/oa/v3/boundaries/{z}/{x}/{y}.pbf",
    layer: "boundaries",
    code: "areacd"
}



const bounds = [[-1.390800, 51.033622], [-1.274071, 51.117101]];

const baseMap = {
        key: "omt",
        label: "OpenMapTiles",
        path: "./style-ons-light.json"
    }

let map;

let outputAreas=["E00118142", "E00118146", "E00118156", "E00118157", "E00118158", "E00184995", "E00118144"];



</script>
<div class="map">
<Map id="map" location={{zoom:13.4, lng: -1.3065931828408566, lat: 51.07846501200899}} style={baseMap.path} bind:map={map} controls={true}>
    <MapSource id="oaBoundaries" type="vector" url={oaBoundaries.url} layer={oaBoundaries.layer} promoteId={oaBoundaries.code} maxzoom={12} minzoom={5}>
        <MapLayer id="oaBoundaries" type="fill" sourceLayer={oaBoundaries.layer} minzoom={5} paint={{
						"fill-color":'black',
						"fill-opacity":0.2,
						"fill-outline-color": 'rgba(0,0,0,1)'
					}} filter={['in', oaBoundaries.code, ...outputAreas]}/>

    </MapSource>
    <MapSource id="shopVoronoi" type="geojson" data={shopVoronoi}>
        <MapLayer id="shopVoronoi" type="line"
				  		paint={{
				  			'line-color': 'blue',
                            'line-width':2
				  			
				  		}}>
        </MapLayer>
    </MapSource>   
    <MapSource id="points" type="geojson" data={points}>
        <MapLayer id="points" type="circle"
				  		paint={{
                            "circle-radius": [
                                "match",
                                ["get", "type"],              // property name in features
                                "post_office", 5,     // if type === 'post_office', use red
                                "shops", 5,           // if type === 'shops', use blue
                                7                     // default color
                                ],
                            "circle-color": [
                                "match",
                                ["get", "type"],              // property name in features
                                "post_office", "#22d0b6",     // if type === 'post_office', use red
                                "shops", "#27a0cc",           // if type === 'shops', use blue
                                "#f66068"                     // default color
                                ],
                            "circle-stroke-color": "#414042",
                            "circle-stroke-width": 2
                            }}>
        </MapLayer>
    </MapSource>   


</Map>
</div>




<style>
    .map {
		height: 600px;
	}
</style>