param([switch]$Run,[switch]$IntegrationTests)
$ErrorActionPreference = 'Stop'
Set-Location -LiteralPath $PSScriptRoot
$candidates = @()
if ($env:JAVA_HOME) { $candidates += $env:JAVA_HOME }
$candidates += @(Get-ChildItem -Path "$env:USERPROFILE\.p2\pool\plugins\org.eclipse.justj.openjdk.hotspot.jre.full.win32.x86_64_*\jre" -Directory -ErrorAction SilentlyContinue | Sort-Object FullName -Descending | ForEach-Object FullName)
$candidates += @(Get-ChildItem -Path 'C:\Program Files\Java\jdk*','C:\Program Files\Eclipse Adoptium\jdk*',"$env:USERPROFILE\.jdks\*" -Directory -ErrorAction SilentlyContinue | ForEach-Object FullName)
$selected = $null
foreach ($candidate in $candidates) {
    if (Test-Path (Join-Path $candidate 'bin\javac.exe')) {
        $version = & (Join-Path $candidate 'bin\javac.exe') -version 2>&1 | Out-String
        if ($version -match 'javac (\d+)' -and [int]$Matches[1] -ge 21) { $selected = $candidate; break }
    }
}
if (-not $selected) { throw 'Java JDK 21 or newer is required.' }
$env:JAVA_HOME = $selected
$maven = Join-Path $PSScriptRoot 'target\build-tools\apache-maven-3.9.9\bin\mvn.cmd'
if (-not (Test-Path $maven)) {
    New-Item -ItemType Directory -Force target/build-tools | Out-Null
    $url = 'https://repo.maven.apache.org/maven2/org/apache/maven/apache-maven/3.9.9/apache-maven-3.9.9-bin.zip'
    Invoke-WebRequest -Uri $url -OutFile target/apache-maven.zip
    $expected = (Invoke-WebRequest -Uri ($url + '.sha512')).Content.Trim()
    if ((Get-FileHash target/apache-maven.zip -Algorithm SHA512).Hash -ne $expected) { throw 'Maven download checksum mismatch.' }
    Expand-Archive -LiteralPath target/apache-maven.zip -DestinationPath target/build-tools -Force
}
$arguments = @('-B','-q','-Dmaven.repo.local=target/maven-repository')
if ($IntegrationTests) { $arguments += '-Dhtms.integration=true' }
$arguments += @('verify','dependency:copy-dependencies','-DincludeScope=runtime','-DoutputDirectory=target/runtime-lib')
& $maven @arguments
if ($LASTEXITCODE -ne 0) { throw 'Build or tests failed. See target/surefire-reports.' }
if ($Run) {
    New-Item -ItemType Directory -Force target/javafx-modules | Out-Null
    Get-ChildItem target/runtime-lib -Filter 'javafx-*-win.jar' | Copy-Item -Destination target/javafx-modules -Force
    & (Join-Path $selected 'bin\java.exe') --enable-native-access=ALL-UNNAMED --module-path target/javafx-modules --add-modules javafx.controls,javafx.fxml -cp 'target/classes;target/runtime-lib/*' com.htms.Main
    if ($LASTEXITCODE -ne 0) { throw 'HTMS exited with an error.' }
}
