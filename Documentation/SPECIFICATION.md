# MacPhoto Utility for macOS
## Development Plan — 2.5 × 3.5-inch Prints

**Platform:** MacBook Neo, macOS  
**Target computer:** Macintosh Plus, 4 MB RAM, System 6  
**Application:** Native macOS utility written in Swift  
**Primary purpose:** Prepare photographs for small physical prints and create screen-ready monochrome images for the Macintosh Plus.

## 1. Project objective

Build a native macOS application that imports photographs, allows the user to compose each image, and exports two types of output:

1. **Print image:** High-resolution greyscale image specifically prepared for a 2.5 × 3.5-inch print.
2. **Screen image:** Exactly 512 × 342 pixels, 1-bit monochrome using Atkinson dithering, exportable as PICT or MacPaint `.MAC`.

The application should support individual images and batch processing. Each photograph must retain its own crop, zoom, rotation and positioning settings, even when multiple photographs share the same output settings.

The application must not alter original photographs.

The initial release does not need direct scanner control, printer communication, automatic file transfer or networked archiving.

## 2. Fixed print specification

The print workflow is restricted to one physical print size: **2.5 × 3.5 inches**.

Use **300 PPI as the default output resolution**, with an optional 360 PPI setting if testing shows a practical benefit.

| Setting | 300 PPI | 360 PPI |
|---|---:|---:|
| Physical print | 2.5 × 3.5 in | 2.5 × 3.5 in |
| Portrait output | 750 × 1050 px | 900 × 1260 px |
| Landscape output | 1050 × 750 px | 1260 × 900 px |
| Pixel depth | 8-bit greyscale | 8-bit greyscale |
| Physical dimensions | 2.5 × 3.5 in | 2.5 × 3.5 in |

These dimensions must be exact. The user must not be offered 5 × 7-inch, 10 × 14-inch or arbitrary print-size options.

The user may choose portrait or landscape orientation, but the application must retain the 2.5:3.5 physical aspect ratio. Orientation changes the ordering of the dimensions, not the print size.

Do not stretch photographs to fill the output. If the source aspect ratio differs, show the crop and let the user adjust it.

The default should be 300 PPI. Keep 360 PPI optional until the full pipeline has been tested; a higher pixel count does not automatically produce a visibly better print if the source image or printer cannot benefit from it.

## 3. Input formats

Support importing:

- JPEG/JPG
- HEIC/HEIF
- PNG
- TIFF

Requirements:

- Read image dimensions and metadata.
- Apply EXIF orientation correctly.
- Convert source photographs into a consistent greyscale working representation.
- Handle colour and greyscale photographs.
- Report corrupt, unsupported or missing files clearly.
- Never modify original files.
- Support importing individual files or folders.

Keep the original source reference and processing settings in the project rather than replacing the source with a converted file.

## 4. Main application interface

Use a native macOS interface built with SwiftUI and AppKit where appropriate.

Provide three main working areas:

1. **Photo queue:** Thumbnail overview of imported photographs.
2. **Composition editor:** Crop, zoom, rotation and positioning.
3. **Output and export:** Print profile, screen-image format and destination.

Each photograph should show its filename, source dimensions, orientation and processing status.

The interface should make the distinction between the physical print output and the Macintosh Plus screen output clear.

## 5. Composition editor

Allow the user to:

- Crop a photograph.
- Zoom in and out.
- Reposition the image.
- Rotate it in 90-degree increments.
- Reset the composition.
- Preview the exact print framing.
- Preview the screen-image result separately.

Composition must be saved individually for every photograph.

If the user changes between 300 and 360 PPI, the composition must remain the same. The application should render the same selected crop at the new output dimensions, not change the framing.

For a print image, the final output aspect ratio must be exactly 2.5:3.5 or 3.5:2.5, depending on orientation.

Provide a clear crop boundary. Do not silently remove parts of the source image when aspect ratios differ.

## 6. Print-image output

Generate an 8-bit greyscale image at the selected fixed dimensions.

### Output rules

- Default: 1050 × 750 pixels for landscape or 750 × 1050 for portrait, at 300 PPI.
- Optional: 1260 × 900 pixels for landscape or 900 × 1260 for portrait, at 360 PPI.
- Store the full-resolution greyscale image.
- Include physical print dimensions and resolution metadata where supported.
- Do not reduce print output to 512 × 342 pixels.
- Do not apply 1-bit dithering to the print master.
- Use a documented resampling method.
- Preserve the selected crop and orientation.
- Validate output dimensions before reporting success.

Use a simple, documented native MacPhoto print-image format for the first release. The format should be easy for a future 68000 C application to read.

The format specification must define:

- Magic identifier.
- Version.
- Header length.
- Width and height.
- Bit depth.
- Pixel encoding.
- Row layout.
- Byte order for multi-byte fields.
- Pixel data offset and length.
- Physical print size and PPI fields, if included.
- Optional integrity checksum.

Do not write native Swift structures directly to disk and assume they form a portable file format. Serialise every field explicitly.

A lossless 8-bit greyscale payload is sufficient for the initial implementation. Compression is not required.

## 7. Screen-image output

Independently of print output, allow the user to create a screen-ready image for the Macintosh Plus.

Requirements:

- Exactly 512 × 342 pixels.
- 1-bit monochrome.
- Deterministic Atkinson dithering.
- Preview of the actual final monochrome image.
- Export as PICT or MacPaint `.MAC`.

The screen image must use the selected composition, but it must be rendered specifically for the screen dimensions. It must not be generated by shrinking the final print file as an intermediate shortcut if that produces poorer dithering or composition.

### PICT export

Implement a valid PICT file using a documented and tested encoding appropriate to the target System 6 environment.

### MacPaint export

A MacPaint document uses a 576 × 720 pixel canvas. The `.MAC` exporter must create a valid MacPaint document and place the 512 × 342 screen image onto that canvas according to a documented positioning rule.

Do not write a 512 × 342 bitmap and simply give it a `.MAC` extension.

Validate both output formats structurally and open them on the real Macintosh Plus before declaring compatibility confirmed.

## 8. Batch processing

Support processing multiple photographs in one session.

The user should be able to:

- Import a folder or select individual files.
- Set the common print profile to 300 or 360 PPI.
- Choose which output types to generate.
- Adjust each photograph's crop individually.
- Preview each composition before exporting.
- Select a destination folder.
- View progress and errors.

Shared settings must not overwrite individual crop, zoom, rotation or positioning choices.

Batch processing should continue if one photograph fails, while reporting the failure clearly.

Never overwrite an existing output silently. Provide an explicit conflict-resolution choice.

Process images one at a time where practical to keep memory use predictable.

## 9. Project saving

Allow the user to save and reopen a project.

Persist:

- Source file references.
- Queue order.
- Crop and composition settings.
- Output type selection.
- PPI selection.
- Destination folder.
- Export history.
- Errors and warnings.

Do not embed every original photograph into the project by default.

If a source file has moved or disappeared, report the problem and offer relinking. Never silently substitute another photograph.

An export should be marked successful only after the file has been written and validated locally. Do not imply that it has been transferred to the Macintosh Plus or printed.

## 10. Technical architecture

Keep the application divided into small, testable modules.

### Image importer
Reads source files, normalises orientation and converts images into a working greyscale representation.

### Composition engine
Calculates crop rectangles, rotation, scaling and positioning independently of the interface.

### Print renderer
Produces the fixed 2.5 × 3.5-inch greyscale output at the selected PPI.

### Screen renderer
Produces the 512 × 342 canonical monochrome bitmap and applies deterministic Atkinson dithering.

### Exporters
Write the native print-image format, PICT, MacPaint and export manifest.

### Project manager
Maintains the queue, per-image composition, project persistence, export settings and error handling.

### Test tools
Validate image dimensions, file structures, metadata and pixel data without requiring the main interface to run.

Keep the print renderer separate from the screen renderer so that changes to the screen dithering cannot accidentally alter print output.

## 11. Testing requirements

### Print tests

Verify:

- Correct 750 × 1050 portrait output at 300 PPI.
- Correct 1050 × 750 landscape output at 300 PPI.
- Correct 900 × 1260 portrait output at 360 PPI.
- Correct 1260 × 900 landscape output at 360 PPI.
- Greyscale output at 8 bits per pixel.
- Correct crop and orientation.
- No unintended stretching.
- Correct physical dimensions and PPI metadata where applicable.

Test photographs with different source aspect ratios, including portrait photos, landscapes and square images.

### Screen tests

Verify:

- Exact 512 × 342 dimensions.
- 1-bit pixel depth.
- Deterministic Atkinson output.
- Valid PICT and MacPaint structures.
- Correct MacPaint canvas placement.
- Acceptable appearance on the real Macintosh Plus.

### Batch tests

Verify:

- Mixed portrait and landscape photographs.
- Individual crop settings survive batch export.
- Shared PPI settings do not alter composition.
- One failed image does not abort the entire batch.
- Existing files are not silently overwritten.
- Source photographs remain unchanged.

### Real-hardware tests

Transfer generated files to the Macintosh Plus and test:

1. PICT opening and display.
2. MacPaint `.MAC` opening.
3. Screen-image appearance.
4. Native print-image import into MacPhoto once that importer exists.
5. Portrait and landscape viewing.
6. Screensaver use of screen images.

Modern Mac validation is not a substitute for testing on the actual Plus.

## 12. Development roadmap

### Phase 0 — Inspect and specify

- Inspect the repository and build environment.
- Confirm the macOS deployment target and Swift toolchain.
- Define the fixed print profiles.
- Specify the native print-image format.
- Research PICT and MacPaint compatibility requirements.
- Establish test images and expected output dimensions.

**Deliverable:** A buildable project skeleton, written format specifications and a technical-risk report.

### Phase 1 — Conversion engine

- Implement image import and orientation normalisation.
- Implement composition geometry.
- Implement the 2.5 × 3.5-inch print renderer.
- Implement the 512 × 342 screen renderer.
- Implement deterministic Atkinson dithering.
- Add automated tests.

**Deliverable:** A test harness that converts one image into both canonical outputs.

### Phase 2 — File exporters

- Implement native print-image output.
- Implement PICT export.
- Implement MacPaint `.MAC` export.
- Implement file validation and a JSON manifest.
- Add safe filename and overwrite handling.

**Deliverable:** Validated output files and a documented transfer test pack.

### Phase 3 — Single-image application

- Build the main macOS window.
- Add import and composition controls.
- Add print and screen previews.
- Add output selection and destination handling.
- Add progress and clear error messages.

**Deliverable:** A user can import, compose and export one photograph without using command-line tools.

### Phase 4 — Batch processing

- Add folder import and thumbnail queue.
- Add per-image crop settings.
- Add shared output profiles.
- Add batch progress, error recovery and conflict handling.

**Deliverable:** A mixed set of photographs can be processed reliably in one operation.

### Phase 5 — Saved projects

- Add project save and reopen.
- Restore composition and queue state.
- Detect and relink missing source files.
- Record export history.

**Deliverable:** Work can be paused and resumed without losing composition choices.

### Phase 6 — Compatibility and release

- Validate generated screen files on the real Macintosh Plus.
- Validate the native print format with the MacPhoto importer when available.
- Document confirmed compatibility.
- Add a user guide, changelog and example files.
- Verify a clean build from a fresh checkout.

**Deliverable:** A tested, documented initial release.

## 13. Out of scope

Do not implement the following in this release:

- 5 × 7-inch or 10 × 14-inch prints.
- Arbitrary physical print sizes.
- Direct SCSI scanner control.
- Printer drivers or inkjet communication.
- Raspberry Pi printer-bridge integration.
- Automatic transfer to the Macintosh Plus.
- Networked archiving.
- Cloud storage.
- OCR or automatic subject recognition.

Keep future integration possible without adding these features to the initial release.

## 14. Required documentation

Maintain:

- `README.md` — purpose, build and run instructions.
- `DEVELOPMENT_PLAN.md` — phase status and outstanding work.
- `ARCHITECTURE.md` — modules and data flow.
- `FILE_FORMATS.md` — native print, PICT, MacPaint and manifest specifications.
- `COMPATIBILITY.md` — tested System 6 and application compatibility.
- `TESTING.md` — automated and real-hardware procedures.
- `CHANGELOG.md` — user-visible changes.
- `DECISIONS.md` — significant design decisions.

Update documentation alongside code changes.

## 15. Instructions to Claude Code

Begin by inspecting the existing repository and reporting its current state. Do not immediately implement the entire application.

Then:

1. Confirm the available Swift toolchain, SDK and test framework.
2. Create an implementation checklist from this specification.
3. Identify unresolved format and compatibility questions.
4. Implement Phase 0 only.
5. Build and test the result.
6. Update the documentation and report what remains unverified.

For each subsequent phase, implement the smallest coherent feature, run its tests, fix failures and update the documentation before proceeding.

Do not claim that System 6 compatibility is confirmed without real-hardware evidence. Do not silently alter the file format or introduce larger print sizes.

**First milestone:** Import one photograph, crop it, export a correctly sized 2.5 × 3.5-inch greyscale print image and a 512 × 342 Atkinson screen image, then validate both outputs. Build the batch interface only after this pipeline works reliably.
