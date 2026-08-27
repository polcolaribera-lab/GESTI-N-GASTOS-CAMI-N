param(
    [string]$Source = ""
)

$ErrorActionPreference = "Stop"
Add-Type -AssemblyName System.Drawing

$workspaceRoot = Split-Path -Parent $PSScriptRoot
if ([string]::IsNullOrWhiteSpace($Source)) {
    $Source = Join-Path $workspaceRoot "assets\branding\ruta_clara_icon_1024.png"
}

$sourcePath = (Resolve-Path -LiteralPath $Source).Path

function Export-SquarePng {
    param(
        [System.Drawing.Image]$Image,
        [int]$Size,
        [string]$Destination
    )

    $destinationDirectory = Split-Path -Parent $Destination
    New-Item -ItemType Directory -Force -Path $destinationDirectory | Out-Null

    $bitmap = New-Object System.Drawing.Bitmap(
        $Size,
        $Size,
        [System.Drawing.Imaging.PixelFormat]::Format32bppArgb
    )
    try {
        $bitmap.SetResolution(72, 72)
        $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
        try {
            $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml("#0B4F49"))
            $graphics.CompositingMode = [System.Drawing.Drawing2D.CompositingMode]::SourceCopy
            $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
            $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
            $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
            $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
            $graphics.DrawImage($Image, 0, 0, $Size, $Size)
        }
        finally {
            $graphics.Dispose()
        }

        $bitmap.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
    }
    finally {
        $bitmap.Dispose()
    }
}

function Export-FeatureGraphic {
    param(
        [string]$SourcePath,
        [string]$Destination
    )

    $sourceImage = [System.Drawing.Image]::FromFile($SourcePath)
    try {
        $bitmap = New-Object System.Drawing.Bitmap(
            1024,
            500,
            [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
        )
        try {
            $bitmap.SetResolution(72, 72)
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml("#0B4F49"))
                $graphics.CompositingQuality = [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
                $graphics.InterpolationMode = [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
                $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality
                $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::HighQuality
                $graphics.DrawImage($sourceImage, 0, 0, 1024, 500)
            }
            finally {
                $graphics.Dispose()
            }

            $bitmap.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $bitmap.Dispose()
        }
    }
    finally {
        $sourceImage.Dispose()
    }
}

function Convert-ScreenshotToPlayPng {
    param([string]$Path)

    $sourceImage = [System.Drawing.Image]::FromFile($Path)
    $temporaryPath = "$Path.play-ready.png"
    try {
        $bitmap = New-Object System.Drawing.Bitmap(
            $sourceImage.Width,
            $sourceImage.Height,
            [System.Drawing.Imaging.PixelFormat]::Format24bppRgb
        )
        try {
            $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
            try {
                $graphics.Clear([System.Drawing.ColorTranslator]::FromHtml("#F7F8F3"))
                $graphics.DrawImage($sourceImage, 0, 0, $sourceImage.Width, $sourceImage.Height)
            }
            finally {
                $graphics.Dispose()
            }

            $bitmap.Save($temporaryPath, [System.Drawing.Imaging.ImageFormat]::Png)
        }
        finally {
            $bitmap.Dispose()
        }
    }
    finally {
        $sourceImage.Dispose()
    }

    Move-Item -LiteralPath $temporaryPath -Destination $Path -Force
}

$sourceImage = [System.Drawing.Image]::FromFile($sourcePath)
try {
    $androidIcons = @{
        48 = "android\app\src\main\res\mipmap-mdpi\ic_launcher.png"
        72 = "android\app\src\main\res\mipmap-hdpi\ic_launcher.png"
        96 = "android\app\src\main\res\mipmap-xhdpi\ic_launcher.png"
        144 = "android\app\src\main\res\mipmap-xxhdpi\ic_launcher.png"
        192 = "android\app\src\main\res\mipmap-xxxhdpi\ic_launcher.png"
    }

    foreach ($entry in $androidIcons.GetEnumerator()) {
        Export-SquarePng `
            -Image $sourceImage `
            -Size $entry.Key `
            -Destination (Join-Path $workspaceRoot $entry.Value)
    }

    Export-SquarePng `
        -Image $sourceImage `
        -Size 512 `
        -Destination (Join-Path $workspaceRoot "play_store_assets\icon-512.png")
}
finally {
    $sourceImage.Dispose()
}

$featureGraphicSource = Join-Path $workspaceRoot "assets\branding\ruta_clara_feature_graphic_master.png"
if (Test-Path -LiteralPath $featureGraphicSource -PathType Leaf) {
    Export-FeatureGraphic `
        -SourcePath $featureGraphicSource `
        -Destination (Join-Path $workspaceRoot "play_store_assets\feature-graphic-1024x500.png")
}

$screenshotDirectory = Join-Path $workspaceRoot "play_store_assets\screenshots"
if (Test-Path -LiteralPath $screenshotDirectory -PathType Container) {
    $screenshots = @(Get-ChildItem -LiteralPath $screenshotDirectory -Filter "*.png" -File)
    if ($screenshots.Count -gt 8) {
        throw "Se esperaban como maximo ocho capturas de Google Play."
    }

    foreach ($screenshot in $screenshots) {
        Convert-ScreenshotToPlayPng -Path $screenshot.FullName
    }
}

Write-Host "Iconos Android y recursos graficos de Google Play preparados correctamente."
