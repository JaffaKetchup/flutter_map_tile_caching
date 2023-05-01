# Known Issues

{% embed url="https://github.com/JaffaKetchup/flutter_map_tile_caching/issues/" %}

{% hint style="success" %}
Where issues originate in FMTC, I try my hardest to fix them quickly where possible, or provide workarounds if necessary.

Some problems will take longer than others to fix, so please be patient. If you think you can fix the issue, please get in touch and/or create a PR - contributions are always welcome!

Where they don't originate directly in FMTC, I consider donating or creating a bounty to get the bug resolved, if I can't help fix it myself. This money can only come from [donations](./#supporting-me) and [alternative license](./#proprietary-licensing) payments to FMTC.
{% endhint %}

## Isar Stability Issues

{% hint style="warning" %}
**FMTC is currently somewhat unstable for applications with a wide public reach, due to some issues with the Isar dependency.**

These issues are being worked on behind the scenes, but unfortunately, there is no planned release date for the v4, which is planned to include these fixes.

FMTC should behave correctly on the majority of devices, but it can cause fatal app crashes on some devices. v8 is much more stable than v7, as it depends on Isar 3.1.0.

If you're significantly concerned about stability, consider using the '[v6-backporting](https://github.com/JaffaKetchup/flutter\_map\_tile\_caching/tree/v6-backporting)' branch instead of v8. v6 has significantly worse performance, and has some other major downsides, but is likely to be more stable across more platforms. The v6 [documentation](http://localhost:5000/o/1aKKbSpe255wyVNDoFYc/s/YFI6k92MXbd87FM5cPCk/) is still available.
{% endhint %}
