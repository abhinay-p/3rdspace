# Public data sources

Normal Discover and Saved contain publisher-listed places and events. Fictional sample records are isolated to the local business preview and deterministic tests.

## Events

- [National Park Service API](https://www.nps.gov/subjects/developer/api-documentation.htm): 500 source records retrieved October 25, 2026, at 22:15 UTC. The publisher reported 1,425 records. The snapshot contains selected pages; it is not comprehensive.
- [Library of Congress public events API](https://www.loc.gov/apis/json-and-yaml/): 100 publisher records retrieved at the same time. Online-only events are omitted from the physical map.

The app expands only dates explicitly supplied by the publisher, excludes canceled dates and closure notices, requires usable times and coordinates, and keeps occurrence identifiers stable. Unknown or ambiguous time zones are omitted rather than guessed. Events without exact meeting coordinates are not placed at a different event's coordinates.

Every event retains an organizer link. Registration, availability, fees, meeting points, and cancellations should be checked there.

Live refreshes paginate within explicit limits. NPS uses the publicly available DEMO_KEY, whose shared quota is unsuitable for large-scale deployment. The app throttles NPS requests and preserves cached listings on failure. A deployed service should use its own provider allocation and server-side cache. No private API credential is embedded.

## Places

The [NPS public Points of Interest service](https://mapservices.nps.gov/arcgis/rest/services/NationalDatasets/NPS_Public_POIs/MapServer/0) supplies named visitor centers, museums, gardens, and related public place types.

The October 25 snapshot contains 1,066 source points across 348 park units. Applying the app's US geometry and availability rules yields 775 mapped places in 244 units, including 42 points in Alaska and 8 in Hawaii. This is selected NPS inventory, not every business or place in every state. Unknown operating hours or access do not imply a place is currently open.

Place inventory never generates fictional events. Coordinates remain the publisher's point coordinates.

## Geography and time zones

- The US boundary derives from the [Census Bureau TIGERweb USLandmass States layer](https://tigerweb.geo.census.gov/arcgis/rest/services/TIGERweb/USLandmass/MapServer/0), January 1, 2026 vintage. Geometry was generalized to 0.015 degrees and dissolved into country components. It covers the 50 states and Washington, DC. A bundled mask hides surrounding countries; separate camera presets make mainland, Alaska, and Hawaii usable on an iPhone. Generalized geometry is for display, not precise boundary decisions.
- The park time-zone lookup derives from official NPS points using [timezonefinder](https://github.com/jannikmi/timezonefinder) 9.0.0 and [timezone-boundary-builder](https://github.com/evansiroky/timezone-boundary-builder). Only units whose returned coordinates resolve to a single IANA time zone are included; multi-zone units are omitted. The derived lookup is provided under [ODbL 1.0](https://opendatacommons.org/licenses/odbl/1-0/), with attribution to those projects and their geographic data contributors. No timezonefinder runtime dependency is included.

Exact retrieval timestamps, queries, completeness flags, and provenance are bundled in Resources/public-source-metadata.json. Each public feed keeps its own freshness timestamp; loading an old snapshot does not mark it freshly retrieved.
