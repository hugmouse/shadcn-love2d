-- Real issues from love2d/love, sorted by most comments
return {
    {
        id = "LOVE-578",
        label = "Feature",
        title = "Fix callback naming",
        description =
        "We should really find a better way of naming callbacks, just look at the joystick ones, the function names are getting long, and are hard to read. Related, why are they not camelCase?",
        status = "backlog",
        priority = "medium",
    },
    {
        id = "LOVE-647",
        label = "Feature",
        title = "Renaming Source/Video:seek/tell",
        description =
        "seek and tell set and get a property of the Source, rather than do an action on it, so a set/get prefix is expected. The name tell isn't super obvious either. How about set/getLocation?",
        status = "backlog",
        priority = "low",
    },
    {
        id = "LOVE-1130",
        label = "Feature",
        title = "A nicer love.physics API",
        description =
        "The current physics API isn't exactly nice. Fixtures especially are pains to deal with. Ideally we'd have some API that matches the love Hello World feel: just a few lines to do the simple things, but if you want to, you can get a more advanced API.",
        status = "todo",
        priority = "high",
    },
    {
        id = "LOVE-1455",
        label = "Bug",
        title = "l.a.newSource with 'queue' type returns 'stream'",
        description =
        "love.audio.newSource can be given a SourceType of queue, and instead of erroring, it creates a stream source. Users might not expect this separation since all 3 types are in one definition.",
        status = "todo",
        priority = "medium",
    },
    {
        id = "LOVE-1923",
        label = "Bug",
        title = "Text width calculated incorrectly with highdpi",
        description =
        "The text width is calculated incorrectly when highdpi is enabled. In computeGlyphPositions the string splits into glyph pairs, so when calculating the width the code rounds the value for a pair of characters, creating differences per character.",
        status = "in_progress",
        priority = "high",
    },
    {
        id = "LOVE-1205",
        label = "Feature",
        title = "Enable 3rd party extensions",
        description =
        "It would be nice to have a plugins directory where subdirectories define new C++ modules to be compiled into the love binary. This will make it easy for 3rd parties to add additional non-core functionality, especially for mobile platforms.",
        status = "backlog",
        priority = "medium",
    },
    {
        id = "LOVE-1640",
        label = "Feature",
        title = "C API",
        description =
        "A plain C external API for LOVE would allow any number of other languages to write LOVE code and make it easier to improve performance via LuaJIT's FFI. That said, it would be a lot to maintain.",
        status = "in_progress",
        priority = "high",
    },
    {
        id = "LOVE-1764",
        label = "Feature",
        title = "Consider using MojoAL instead of OpenALSoft",
        description =
        "MojoAL is zlib-licensed, has an identical API to OpenALSoft, is written in C in a single source file, requires only SDL2, and would eliminate the OpenAL32.dll dependency.",
        status = "todo",
        priority = "medium",
    },
    {
        id = "LOVE-1021",
        label = "Feature",
        title = "Expose coordinate of a specific glyph in a string",
        description =
        "Getting cursor position for an input box requires looping through the string and measuring substrings. This becomes very tedious for right-aligned or justified text. Propose exposing getGlyphPosition.",
        status = "backlog",
        priority = "low",
    },
    {
        id = "LOVE-1451",
        label = "Feature",
        title = "Immediate mesh rendering / vertex submission API",
        description =
        "An immediate mode vertex submission API would provide a low friction way to submit arbitrary textured geometry, a versatile primitive for building other rendering APIs, and a way to experiment with vertex attributes in shaders.",
        status = "todo",
        priority = "medium",
    },
    {
        id = "LOVE-1595",
        label = "Feature",
        title = "love.system.getOS() should return OS version info",
        description =
        "The information is returned after the OS version string. Various return values of love.system.getOS() in various OS. If no version information is available, notably in Linux, then only the 1st return value is valid.",
        status = "backlog",
        priority = "low",
    },
    {
        id = "LOVE-1618",
        label = "Bug",
        title = "Inconsistencies between Windows and Linux with love.graphics.circle",
        description =
        "Integration tests which compare game frames with pre-existing screenshots show rendering differences between Windows and Linux for love.graphics.circle. The circle rasterization produces different pixels.",
        status = "in_progress",
        priority = "medium",
    },
    {
        id = "LOVE-2089",
        label = "Feature",
        title = "Support for video types other than Theora",
        description =
        "It would be nice to support videos other than Ogg Theora in LOVE2D. One approach is using libVLC or libvlcpp. Theora is outdated and limits the video formats available to developers.",
        status = "todo",
        priority = "medium",
    },
    {
        id = "LOVE-664",
        label = "Feature",
        title = "lineCaps and lineJoins",
        description =
        "lineCaps and lineJoins are very handy as they let you have things like smooth lines. The implementation won't be easy but it will improve the quality of LOVE games. This is a feature found in HTML5 canvases.",
        status = "backlog",
        priority = "medium",
    },
    {
        id = "LOVE-1625",
        label = "Feature",
        title = "AV1 video playback",
        description =
        "Ogg Theora isn't very good as a format in general, and the backend code in love is hard to maintain and has bugs. The main reason Theora was used is at the time all the alternatives had other drawbacks. AV1 is now a strong candidate.",
        status = "todo",
        priority = "high",
    },
    {
        id = "LOVE-2008",
        label = "Feature",
        title = "love.system.getArch() proposal",
        description =
        "Similar to love.system.getOS(), it should return the architecture that Love is running on. This is particularly useful for loading native code on x86_64 and ARM platforms.",
        status = "backlog",
        priority = "low",
    },
    {
        id = "LOVE-1889",
        label = "Feature",
        title = "Phase out 32-bit binaries",
        description =
        "Currently LOVE still provides 32-bit builds for Windows and Android. On other platforms, 32-bit binaries are no longer provided. This only affects binaries we distribute; users can still compile their own.",
        status = "in_progress",
        priority = "medium",
    },
    {
        id = "LOVE-1881",
        label = "Bug",
        title = "AudioSource stop should do nothing if not playing",
        description =
        "Right now you need to keep track of what sounds are playing or check if a sound is playing before telling it to stop. Would be nice if stop did nothing if it wasn't playing.",
        status = "done",
        priority = "low",
    },
    {
        id = "LOVE-1319",
        label = "Feature",
        title = "Support for Opus audio codec",
        description =
        "It would be nice to have support for the Opus audio codec. The big advantage is that Opus is a good speech codec at moderate bitrates, which can save a fair bit of space for dialogue-heavy games.",
        status = "todo",
        priority = "medium",
    },
    {
        id = "LOVE-2300",
        label = "Feature",
        title = "Quad UV rotation",
        description =
        "A utility added into the Quad implementation to rotate a quad's rendering arguments by increments of 90 degrees. This simplifies implementing per-frame rotation in atlases drastically.",
        status = "backlog",
        priority = "low",
    },
    {
        id = "LOVE-1398",
        label = "Feature",
        title = "Decoder and RecordingDevice reuse existing SoundData",
        description =
        "Allow Decoder:decode and RecordingDevice:getData to accept an existing SoundData to dump data into, or give users access to the internal getBuffer function to avoid repeated allocations.",
        status = "backlog",
        priority = "low",
    },
    {
        id = "LOVE-890",
        label = "Feature",
        title = "LOVE development tools",
        description =
        "LOVE currently works nicely as a development and runtime library without any split between the two, but there are some things missing from the development side which wouldn't make sense to include in end-user runtime distributions.",
        status = "canceled",
        priority = "medium",
    },
    {
        id = "LOVE-2155",
        label = "Bug",
        title = "Incorrect image scaling with system zoom on Windows",
        description =
        "On LOVE 12, images don't scale correctly when on high DPI screens, or when the system zoom is set at a non-multiple of 100%. The rendered output doesn't match the expected pixel dimensions.",
        status = "in_progress",
        priority = "high",
    },
    {
        id = "LOVE-2190",
        label = "Bug",
        title = "love.math.triangulate should return nil on failure",
        description =
        "Currently love.math.triangulate terminates the runtime and throws a cryptic error if triangulation fails, instead of returning false or nil. A failed triangulation shouldn't be a fatal error.",
        status = "todo",
        priority = "medium",
    },
    {
        id = "LOVE-1766",
        label = "Feature",
        title = "Write image to clipboard",
        description =
        "Currently love.system.setClipboardText only supports text, not images. It would be useful to write images to the clipboard, similar to copying part of an image in MS Paint and pasting it elsewhere.",
        status = "backlog",
        priority = "low",
    },
}
