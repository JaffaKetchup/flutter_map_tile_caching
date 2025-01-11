---
description: A plugin for 'flutter_map' providing advanced offline functionality
cover: .gitbook/assets/FMTC Banner.png
coverY: 0
layout:
  cover:
    visible: true
    size: full
  title:
    visible: true
  description:
    visible: false
  tableOfContents:
    visible: true
  outline:
    visible: true
  pagination:
    visible: false
---

# flutter\_map\_tile\_caching

[![pub.dev](https://img.shields.io/pub/v/flutter_map_tile_caching.svg?label=Latest+Version)](https://pub.dev/packages/flutter_map_tile_caching) [![stars](https://badgen.net/github/stars/JaffaKetchup/flutter_map_tile_caching?label=stars\&color=green\&icon=github)](https://github.com/JaffaKetchup/flutter_map_tile_caching/stargazers) [![likes](https://img.shields.io/pub/likes/flutter_map_tile_caching?logo=flutter)](https://pub.dev/packages/flutter_map_tile_caching/score)        [![Open Issues](https://badgen.net/github/open-issues/JaffaKetchup/flutter_map_tile_caching?label=Open+Issues\&color=green)](https://github.com/JaffaKetchup/flutter_map_tile_caching/issues) [![Open PRs](https://badgen.net/github/open-prs/JaffaKetchup/flutter_map_tile_caching?label=Open+PRs\&color=green)](https://github.com/JaffaKetchup/flutter_map_tile_caching/pulls)

## Highlights

<table data-card-size="large" data-view="cards" data-full-width="true"><thead><tr><th></th><th></th><th></th><th data-hidden data-card-cover data-type="files"></th></tr></thead><tbody><tr><td><p><mark style="color:blue;">◉</mark> 📲</p><p><strong>Integrated Caching × Bulk Downloading</strong></p></td><td>Get both dynamic browse caching that works automatically as the user browses the map, and bulk downloading to preload regions onto the user's device, all in one convenient, integrated API!</td><td><ul><li><a data-footnote-ref href="#user-content-fn-1">Multi-cache ('store') support</a> with <a data-footnote-ref href="#user-content-fn-2">minimized tile duplication</a> and <a data-footnote-ref href="#user-content-fn-3">maximum flexibility</a></li><li><a data-footnote-ref href="#user-content-fn-4">Download any shape of area</a></li><li><a data-footnote-ref href="#user-content-fn-5">Automatic sea tile skipping</a> when bulk downloading</li><li><a data-footnote-ref href="#user-content-fn-6">Optional download rate limiting</a></li><li>Recoverable failed bulk downloads</li></ul></td><td></td></tr><tr><td><p><mark style="color:red;">◉</mark> 🏃</p><p><strong>Ultra-fast &#x26; Performant</strong></p></td><td>No need to bore your users to death anymore! Bulk downloading is super-fast, and can even reach speeds of over 1000 tiles per second<a data-footnote-ref href="#user-content-fn-7">*</a>. Existing cached tiles can be displayed on the map almost instantly.</td><td><ul><li>Multi-threaded setup to minimize load on main thread, even when browse caching</li><li>Streamlined internals to reduce memory consumption</li><li>Successfully downloaded tiles aren't re-downloaded when an unexpectedly failed download is recovered</li></ul></td><td></td></tr><tr><td><p><mark style="color:green;">◉</mark> 🧩</p><p><strong>Import &#x26; Export</strong></p></td><td>Export and share stores, then import them later, or on other devices! You could even remote control your organization's devices, by pushing tiles to them, keeping your tile requests (&#x26; costs) low!</td><td></td><td></td></tr><tr><td><p><mark style="color:purple;">◉</mark> 💖</p><p><strong>Quick To Implement &#x26; Easy To Experiment</strong></p></td><td>A basic caching implementation can be setup in four quick steps, and shouldn't even take 5 minutes to set-up. Check out our <a data-mention href="get-started/quickstart.md">quickstart.md</a> instructions.</td><td>Ready to experiment with bulk downloading, but don't want to make costly and slow tile requests? Check out the testing tile server included in the FMTC project: <a data-mention href="usage/bulk-downloading/testing-tile-server.md">testing-tile-server.md</a>!</td><td></td></tr></tbody></table>

### Trusted by many

In addition to our generous [supporters](supporters.md), FMTC is also trusted and [used by businesses](#user-content-fn-8)[^8] all around the world. Here's just a few!

<table data-card-size="large" data-view="cards"><thead><tr><th align="center"></th><th><select><option value="Zc98uj3O3XSR" label="Paid alternative license" color="blue"></option><option value="OXddfK5XeRk1" label="Free alternative license (non-GPL open-source)" color="blue"></option></select></th><th data-hidden data-card-cover data-type="files"></th><th data-hidden data-card-target data-type="content-ref"></th></tr></thead><tbody><tr><td align="center">Lafayette GPS</td><td><span data-option="Zc98uj3O3XSR">Paid alternative license</span></td><td><a href=".gitbook/assets/Lafayette GPS Logo.png">Lafayette GPS Logo.png</a></td><td><a href="https://gps.lafayette.se/">https://gps.lafayette.se/</a></td></tr><tr><td align="center"><strong>P</strong>itchero GPS</td><td><span data-option="Zc98uj3O3XSR">Paid alternative license</span></td><td><a href=".gitbook/assets/Pitchero GPS Logo.png">Pitchero GPS Logo.png</a></td><td><a href="https://www.pitcherogps.com">https://www.pitcherogps.com </a></td></tr><tr><td align="center">nventive</td><td><span data-option="Zc98uj3O3XSR">Paid alternative license</span></td><td><a href=".gitbook/assets/nventive Logo.png">nventive Logo.png</a></td><td><a href="https://nventive.com/">https://nventive.com/</a></td></tr><tr><td align="center">wemove digital solutions GmbH (contracting for Lower Saxony Ministry for the Environment, Energy and Climate Protection)</td><td><span data-option="OXddfK5XeRk1">Free alternative license (non-GPL open-source)</span></td><td><a href=".gitbook/assets/wemove Logo.png">wemove Logo.png</a></td><td><a href="https://www.wemove.com/website/de/project/umweltnavi-niedersachen">https://www.wemove.com/website/de/project/umweltnavi-niedersachen</a></td></tr></tbody></table>

### How can FMTC elevate my app to the next level?

Easy! Take a look at Google Maps, or Strava, or whichever other app of your choice.

<details>

<summary>More than just preset rectangles</summary>

Whether it's walking along a remote winding river using the Line region, downloading all of central London ready for that weekend exploration using the Circle region (roaming fees + maps gets expensive fast!), or tracking your belongings across a vast, shapeless space using the Custom Polygon region, FMTC has your user's back - but not all of their storage space!

</details>

<details>

<summary>Keep storage usage efficient</summary>

With Sea Tile Skipping, you can avoid storing unnecessary tiles of pure sea, then use the map client's functionality to just paint the spaces the same color as the sea.

Highly flexible stores allow for multiple stores to be used to more efficiently store and control areas, and tiles can be used by multiple stores without duplication.

Import/export functionality allows users to temporarily offload stores to another device to keep their device lightweight until they require those tiles, without having to download them from the origin server again.

_**Raster tiles do consume more storage than vector tiles.** Vector tile support is planned and already possible with some custom integration._

</details>

<details>

<summary>Highly controllable and flexible downloads</summary>

Bulk downloads can be paused and resumed at any time, and with download recovery, downloads that stopped unexpectedly can be started right from where they left off, without your user even knowing something went wrong.

</details>

<details>

<summary>I wonder how much it costs the app developers?</summary>

FMTC supports bulk downloading from any tile server\*[^9], so you can choose whichever one suits you best.

Our browse caching mechanism doesn't result in any extra requests to the tile server, and in fact can reduce costs by serving tiles to users from their local cache without cost. Or, if you're running your own server, you can reduce the strain on it, keeping it snappy with fewer resources!

Downloads can be rate limited to avoid running up to the server's rate limit or excess fee.

And with export/import functionality, user's can download regions just once, then keep the download themselves for another time. Or, you can provide a bundle of tiles to all your user's, while still allow it to be updated per-user in future!\*[^10]

For (proprietary) licensing information, as FMTC is licensed under GPL-v3, please see [proprietary-licensing.md](proprietary-licensing.md "mention").

</details>

***

## Supporting Me

This project is wholly open source and funded by generous supporters like you! Any amount you can spare that you think FMTC deserves is hugely appreciated, and means a lot to me :)

{% content-ref url="supporters.md" %}
[supporters.md](supporters.md)
{% endcontent-ref %}

## (Proprietary) Licensing

{% hint style="warning" %}
**FMTC is licensed under GPL-v3.**

If you're developing an application that isn't licensed under GPL, this affects you and your application's legal right to distribution.
{% endhint %}

{% content-ref url="proprietary-licensing.md" %}
[proprietary-licensing.md](proprietary-licensing.md)
{% endcontent-ref %}

## Get Help

Not quite sure about something? No problem, I'm happy to help!

Please get in touch via the correct method below for your issue, and I'll be there to help ASAP!

* For bug reports & feature requests: [GitHub Issues](https://github.com/JaffaKetchup/flutter_map_tile_caching/issues)
* For implementation/general support: The _#plugin_ channel on the [flutter\_map Discord server](https://github.com/fleaflet/flutter_map#discord-server)
* For other inquiries and licensing: [fmtc@jaffaketchup.dev](mailto:fmtc@jaffaketchup.dev)

[^1]: Keep your users' tiles organized, and even let them control what goes where!

[^2]: Tiles can belong to multiple stores, and tiles from different sources (template URLs) can be stored in a single store!

[^3]: Use multiple stores at once

[^4]: Download rectangles, circles, line-based, any other freehand polygon, and any combination of those!

[^5]: Avoid downloading redundant, waste-of-space tiles that cover oceans, with this unique functionality, and bless your users with the gift of more usable capacity for useful maps!

[^6]: Downloading from a server with a rate limit? No problem: just enable rate limiting and we'll do our best to stick to it!

[^7]: Speed is very dependent on tile server ability, network delays, and device processing power. Actual speed is likely to be considerably lower.



    1500 tiles was tested from the included testing tile server running on localhost, on a Windows 11 (Intel 12th Gen i7-12700H CPU & DDR5 4800MHz RAM) with 10 downloading threads & a buffer of 500 tiles.

[^8]: Disclaimer: some of these projects/businesses use FMTC licensed under a paid [alternative proprietary license](./#proprietary-licensing), whilst others use an alternative license for free as they are open-source or non-revenue.

[^9]: Those compatible with flutter\_map. Some tile server's may forbid bulk downloading.

[^10]: Some tile servers may forbid this activity. Check your tile server's ToS.
