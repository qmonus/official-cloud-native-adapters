// Code generated by cue get go. DO NOT EDIT.

//cue:generate cue get go github.com/tektoncd/pipeline/pkg/apis/pipeline

package pipeline

// Images holds the images reference for a number of container images used
// across tektoncd pipelines.
#Images: {
	// EntrypointImage is container image containing our entrypoint binary.
	EntrypointImage: string

	// SidecarLogResultsImage is container image containing the binary that fetches results from the steps and logs it to stdout.
	SidecarLogResultsImage: string

	// NopImage is the container image used to kill sidecars.
	NopImage: string

	// GitImage is the container image with Git that we use to implement the Git source step.
	GitImage: string

	// ShellImage is the container image containing bash shell.
	ShellImage: string

	// ShellImageWin is the container image containing powershell.
	ShellImageWin: string

	// GsutilImage is the container image containing gsutil.
	GsutilImage: string

	// PRImage is the container image that we use to implement the PR source step.
	PRImage: string

	// ImageDigestExporterImage is the container image containing our image digest exporter binary.
	ImageDigestExporterImage: string

	// WorkingDirInitImage is the container image containing our working dir init binary.
	WorkingDirInitImage: string
}
