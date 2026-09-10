/// The minimum accepted `itemExtent` shared by picker widgets whose rows
/// must fit the tallest per-row content in the `pickers/` family, in logical
/// pixels.
///
/// [LayrzMultiSelectInput]'s row is the tallest: it wraps a checkbox
/// affordance alongside the item's content plus the shared vertical padding,
/// and needs at least 52 logical pixels to avoid a row overflow.
/// [LayrzDualListInput] has no checkbox in its own desktop panels, but on a
/// compact viewport it delegates entirely to [LayrzMultiSelectInput],
/// forwarding its own `itemExtent` unchanged (see
/// [LayrzDualListInput]'s class doc, "compact delegation") — so a caller
/// passing an `itemExtent` that is safe for the desktop panels but below
/// MultiSelect's own floor would only overflow once that same field is
/// viewed on a narrow viewport. Sharing this constant lets both widgets
/// enforce the one floor that is actually safe for every path either of
/// them can render.
const double kLayrzPickerMinItemExtent = 52.0;
