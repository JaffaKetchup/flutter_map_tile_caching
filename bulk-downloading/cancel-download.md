# Cancel Download

If you need to stop a bulk download early, you can use the `cancel()` method to safely exit. No more tiles will be downloaded, and any tiles still within the buffer (see [buffering.md](foreground/buffering.md "mention")) will be written.

{% hint style="info" %}
There is no support to pause downloads, nor is there planned support.
{% endhint %}
