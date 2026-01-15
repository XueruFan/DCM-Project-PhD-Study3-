# ============================================================
# Copy smoothed fsaverage5 surface data (lh/rh) for rest scans
# + generate TSV log of copied data
#
# Author: Xueru Fan
# Date: 2026-01
# ============================================================

$srcRoot = "F:\devCCNP\Release1\MRI\devCCNP_MRI_Preprocessed\PEK\CCS"
$dstRoot = "E:\PhDproject\CCNP\PEK"
$logFile = Join-Path $dstRoot "sessions.tsv"

# prepare log container
$log = @()

if (!(Test-Path $dstRoot)) {
    New-Item -ItemType Directory -Path $dstRoot | Out-Null
}

Get-ChildItem $srcRoot -Directory | ForEach-Object {

    $sesName = $_.Name
    $sesSrc  = $_.FullName
    $sesDst  = Join-Path $dstRoot $sesName

    # parse subject and session
    if ($sesName -match "^(sub-[^_]+)_(ses\d+)$") {
        $subject = $matches[1]
        $session = $matches[2]
    }
    else {
        return
    }

    Write-Host "Processing $sesName ..."

    $validFiles = @()

    foreach ($rest in @("rest1", "rest2")) {

        $restPath = Join-Path $sesSrc $rest
        if (!(Test-Path $restPath)) {
            continue
        }

        $lh = Get-ChildItem $restPath -Filter "*pp.nofilt.sm6.fsaverage5.lh.nii.gz" -ErrorAction SilentlyContinue
        $rh = Get-ChildItem $restPath -Filter "*pp.nofilt.sm6.fsaverage5.rh.nii.gz" -ErrorAction SilentlyContinue

        if ($lh.Count -gt 0 -and $rh.Count -gt 0) {

            if (!(Test-Path $sesDst)) {
                New-Item -ItemType Directory -Path $sesDst | Out-Null
            }

            Copy-Item $lh.FullName $sesDst -Force
            Copy-Item $rh.FullName $sesDst -Force

            # record log
            $log += [PSCustomObject]@{
                subject = $subject
                session = $session
                rest    = $rest
                lh_file = $lh.Name
                rh_file = $rh.Name
            }

            Write-Host "  $rest copied (lh + rh)"
        }
        else {
            Write-Host "  $rest incomplete, skipped"
        }
    }
}

# write TSV
$log |
    Sort-Object subject, session, rest |
    Export-Csv -Path $logFile -Delimiter "`t" -NoTypeInformation -Encoding UTF8

Write-Host "All done. Log written to $logFile"
