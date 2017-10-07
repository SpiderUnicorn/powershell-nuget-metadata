FROM microsoft/powershell

# copy test / data files
ADD ./NuGetMetadata.psm1 .
ADD ./NuGetMetadata.Tests.ps1 .
ADD ./test ./test

# install pester 
RUN powershell -command Install-Module -Name Pester -Force -SkipPublisherCheck

# run tests when running the container
CMD powershell -command Invoke-Pester ./NuGetMetadata.Tests.ps1 -OutputFile test/results/results.xml -OutputFormat NUnitXml

# create mount point
VOLUME ./test/results