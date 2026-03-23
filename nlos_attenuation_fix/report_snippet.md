## Recommended interpretation for attenuation compensation

If the conservative attenuation result is visually almost identical to the uncompensated reconstruction, that is actually a better outcome than the previous ring artifact.

### Suggested conclusion

- the original attenuation compensation was too aggressive and introduced a strong peripheral artifact;
- the conservative version removes that artifact;
- however, its visual impact is very small, so attenuation compensation should **not** be presented as a major improvement;
- in the final report it is safer to describe attenuation compensation as a minor exploratory refinement with negligible qualitative effect in the current implementation.

### Suggested wording for the report

> We implemented a conservative attenuation compensation term as an exploratory refinement. The aggressive version produced clear edge over-amplification, while the conservative version removed that artifact and kept the reconstruction stable. However, the visual difference with respect to the uncompensated reconstruction remained very small. Therefore, attenuation compensation is reported here as a minor secondary effect rather than as a significant source of reconstruction improvement.
