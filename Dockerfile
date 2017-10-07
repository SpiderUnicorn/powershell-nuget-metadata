FROM microsoft/powershell

# install test tooling (pester)
RUN powershell -command Install-Module -Name Pester -Force -SkipPublisherCheck

# place all files in the container and set it to the work dir
# which will be mounted to extract test results
ADD . /data
WORKDIR /data

# run tests when running the container
CMD powershell -command Invoke-Pester ./NuGetMetadata.Tests.ps1 -OutputFile test/results/results.xml -OutputFormat NUnitXml
