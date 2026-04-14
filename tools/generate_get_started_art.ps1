Add-Type -AssemblyName System.Drawing

$ErrorActionPreference = 'Stop'

$root = Split-Path -Parent $PSScriptRoot
$outputDir = Join-Path $root 'assets\pictures'
$sourcePath = Join-Path $root 'assets\images\branding\futuregate_logo.png'

if (-not (Test-Path $sourcePath)) {
  throw "Source artwork not found: $sourcePath"
}

function New-Color {
  param(
    [int]$R,
    [int]$G,
    [int]$B,
    [int]$A = 255
  )

  return [System.Drawing.Color]::FromArgb($A, $R, $G, $B)
}

function New-RoundedRectPath {
  param(
    [single]$X,
    [single]$Y,
    [single]$Width,
    [single]$Height,
    [single]$Radius
  )

  $path = New-Object System.Drawing.Drawing2D.GraphicsPath
  $diameter = $Radius * 2

  $path.AddArc($X, $Y, $diameter, $diameter, 180, 90)
  $path.AddArc($X + $Width - $diameter, $Y, $diameter, $diameter, 270, 90)
  $path.AddArc(
    $X + $Width - $diameter,
    $Y + $Height - $diameter,
    $diameter,
    $diameter,
    0,
    90
  )
  $path.AddArc($X, $Y + $Height - $diameter, $diameter, $diameter, 90, 90)
  $path.CloseFigure()

  return $path
}

function New-Canvas {
  param(
    [int]$Width,
    [int]$Height
  )

  $bitmap = New-Object System.Drawing.Bitmap $Width, $Height
  $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
  $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
  $graphics.InterpolationMode =
    [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
  $graphics.CompositingQuality =
    [System.Drawing.Drawing2D.CompositingQuality]::HighQuality
  $graphics.PixelOffsetMode =
    [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

  return @{
    Bitmap = $bitmap
    Graphics = $graphics
  }
}

function Draw-Background {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$Width,
    [int]$Height,
    [System.Drawing.Color]$TopLeft,
    [System.Drawing.Color]$BottomRight,
    [System.Drawing.Color]$GlowA,
    [System.Drawing.Color]$GlowB
  )

  $gradient = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    ([System.Drawing.Point]::new(0, 0)),
    ([System.Drawing.Point]::new($Width, $Height)),
    $TopLeft,
    $BottomRight
  )
  $Graphics.FillRectangle($gradient, 0, 0, $Width, $Height)
  $gradient.Dispose()

  $glowBrushA = New-Object System.Drawing.SolidBrush $GlowA
  $glowBrushB = New-Object System.Drawing.SolidBrush $GlowB
  $Graphics.FillEllipse($glowBrushA, -160, -120, 700, 700)
  $Graphics.FillEllipse($glowBrushB, $Width - 560, $Height - 560, 760, 760)
  $Graphics.FillEllipse(
    $glowBrushA,
    [int]($Width * 0.42),
    -90,
    520,
    520
  )
  $glowBrushA.Dispose()
  $glowBrushB.Dispose()
}

function Draw-PortalCore {
  param(
    [System.Drawing.Graphics]$Graphics,
    [System.Drawing.Image]$Source,
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height
  )

  $shadowBrush = New-Object System.Drawing.SolidBrush (New-Color 7 17 54 150)
  $Graphics.FillEllipse($shadowBrush, $X - 40, $Y + $Height - 60, $Width + 80, 120)
  $shadowBrush.Dispose()

  $framePath = New-RoundedRectPath -X $X -Y $Y -Width $Width -Height $Height -Radius 42
  $frameBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    ([System.Drawing.Point]::new($X, $Y)),
    ([System.Drawing.Point]::new($X + $Width, $Y + $Height)),
    (New-Color 255 255 255 34),
    (New-Color 255 255 255 10)
  )
  $Graphics.FillPath($frameBrush, $framePath)
  $frameBrush.Dispose()

  $framePen = New-Object System.Drawing.Pen (New-Color 255 255 255 44), 2.5
  $Graphics.DrawPath($framePen, $framePath)
  $framePen.Dispose()
  $framePath.Dispose()

  $Graphics.DrawImage(
    $Source,
    ([System.Drawing.Rectangle]::new($X + 30, $Y + 24, $Width - 60, $Height - 48))
  )
}

function Draw-Skyline {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$StartX,
    [int]$BaselineY
  )

  $brush = New-Object System.Drawing.SolidBrush (New-Color 255 255 255 30)
  $bars = @(
    @(0, 110, 74),
    @(92, 180, 58),
    @(164, 240, 64),
    @(246, 145, 48)
  )

  foreach ($bar in $bars) {
    $path = New-RoundedRectPath `
      -X ($StartX + $bar[0]) `
      -Y ($BaselineY - $bar[1]) `
      -Width $bar[2] `
      -Height $bar[1] `
      -Radius 18
    $Graphics.FillPath($brush, $path)
    $path.Dispose()
  }

  $brush.Dispose()
}

function Draw-GlassCard {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height,
    [System.Drawing.Color]$Tint
  )

  $cardPath = New-RoundedRectPath -X $X -Y $Y -Width $Width -Height $Height -Radius 28
  $cardBrush = New-Object System.Drawing.Drawing2D.LinearGradientBrush(
    ([System.Drawing.Point]::new($X, $Y)),
    ([System.Drawing.Point]::new($X + $Width, $Y + $Height)),
    (New-Color 255 255 255 42),
    $Tint
  )
  $Graphics.FillPath($cardBrush, $cardPath)
  $cardBrush.Dispose()

  $cardPen = New-Object System.Drawing.Pen (New-Color 255 255 255 54), 2
  $Graphics.DrawPath($cardPen, $cardPath)
  $cardPen.Dispose()
  $cardPath.Dispose()

  $lineBrush = New-Object System.Drawing.SolidBrush (New-Color 255 255 255 110)
  $dotBrush = New-Object System.Drawing.SolidBrush (New-Color 23 186 166 185)
  $Graphics.FillEllipse($dotBrush, $X + 24, $Y + 22, 16, 16)
  $Graphics.FillRectangle($lineBrush, $X + 50, $Y + 24, 120, 12)
  $Graphics.FillRectangle($lineBrush, $X + 24, $Y + 58, $Width - 48, 10)
  $Graphics.FillRectangle($lineBrush, $X + 24, $Y + 82, $Width - 68, 10)
  $Graphics.FillRectangle($lineBrush, $X + 24, $Y + $Height - 42, 90, 12)
  $lineBrush.Dispose()
  $dotBrush.Dispose()
}

function Draw-OrbitalRing {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$X,
    [int]$Y,
    [int]$Width,
    [int]$Height,
    [System.Drawing.Color]$Color,
    [float]$Stroke = 8
  )

  $pen = New-Object System.Drawing.Pen $Color, $Stroke
  $pen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $pen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $Graphics.DrawArc($pen, $X, $Y, $Width, $Height, 18, 280)
  $pen.Dispose()
}

function Draw-OpportunityNodes {
  param(
    [System.Drawing.Graphics]$Graphics,
    [int]$CenterX,
    [int]$CenterY
  )

  $nodeBrush = New-Object System.Drawing.SolidBrush (New-Color 255 255 255 205)
  $linePen = New-Object System.Drawing.Pen (New-Color 20 184 166 150), 4
  $linePen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $linePen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round

  $nodes = @(
    @($($CenterX - 255), $($CenterY - 120)),
    @($($CenterX - 320), $($CenterY + 80)),
    @($($CenterX + 240), $($CenterY - 135)),
    @($($CenterX + 308), $($CenterY + 62)),
    @($CenterX, $($CenterY - 250))
  )

  foreach ($node in $nodes) {
    $Graphics.DrawLine($linePen, $CenterX, $CenterY, $node[0], $node[1])
    $Graphics.FillEllipse($nodeBrush, $node[0] - 16, $node[1] - 16, 32, 32)
  }

  $Graphics.FillEllipse($nodeBrush, $CenterX - 20, $CenterY - 20, 40, 40)
  $nodeBrush.Dispose()
  $linePen.Dispose()
}

function Save-Art {
  param(
    [string]$FileName,
    [scriptblock]$DrawAction
  )

  $canvas = New-Canvas -Width 1600 -Height 1200
  $bitmap = $canvas.Bitmap
  $graphics = $canvas.Graphics

  & $DrawAction $graphics 1600 1200

  $destination = Join-Path $outputDir $FileName
  $bitmap.Save($destination, [System.Drawing.Imaging.ImageFormat]::Png)
  $graphics.Dispose()
  $bitmap.Dispose()
}

$sourceImage = [System.Drawing.Image]::FromFile($sourcePath)
$portalCrop = New-Object System.Drawing.Bitmap 440, 380
$portalGraphics = [System.Drawing.Graphics]::FromImage($portalCrop)
$portalGraphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
$portalGraphics.InterpolationMode =
  [System.Drawing.Drawing2D.InterpolationMode]::HighQualityBicubic
$portalGraphics.DrawImage(
  $sourceImage,
  ([System.Drawing.Rectangle]::new(0, 0, 440, 380)),
  ([System.Drawing.Rectangle]::new(230, 0, 440, 380)),
  [System.Drawing.GraphicsUnit]::Pixel
)
$portalGraphics.Dispose()
$sourceImage.Dispose()

Save-Art -FileName 'get_started_portal.png' -DrawAction {
  param($g, $w, $h)

  Draw-Background `
    -Graphics $g `
    -Width $w `
    -Height $h `
    -TopLeft (New-Color 7 17 54) `
    -BottomRight (New-Color 22 104 215) `
    -GlowA (New-Color 59 34 246 86) `
    -GlowB (New-Color 20 184 166 82)

  Draw-Skyline -Graphics $g -StartX 160 -BaselineY 860
  Draw-OrbitalRing `
    -Graphics $g `
    -X 164 `
    -Y 740 `
    -Width 720 `
    -Height 250 `
    -Color (New-Color 41 202 255 108) `
    -Stroke 10
  Draw-OrbitalRing `
    -Graphics $g `
    -X 290 `
    -Y 692 `
    -Width 1040 `
    -Height 320 `
    -Color (New-Color 255 255 255 78) `
    -Stroke 6

  $trailPen = New-Object System.Drawing.Pen (New-Color 255 255 255 108), 7
  $trailPen.StartCap = [System.Drawing.Drawing2D.LineCap]::Round
  $trailPen.EndCap = [System.Drawing.Drawing2D.LineCap]::Round
  $g.DrawCurve(
    $trailPen,
    @(
      [System.Drawing.Point]::new(80, 1030),
      [System.Drawing.Point]::new(250, 960),
      [System.Drawing.Point]::new(520, 900),
      [System.Drawing.Point]::new(840, 860),
      [System.Drawing.Point]::new(1180, 700)
    )
  )
  $trailPen.Dispose()

  Draw-PortalCore -Graphics $g -Source $portalCrop -X 760 -Y 182 -Width 520 -Height 650

  $sparkBrush = New-Object System.Drawing.SolidBrush (New-Color 255 255 255 156)
  foreach ($point in @(
    @(226, 262), @(292, 210), @(340, 332), @(1210, 202), @(1328, 278), @(1380, 232),
    @(1134, 138), @(1005, 286), @(1236, 504), @(1355, 440)
  )) {
    $g.FillEllipse($sparkBrush, $point[0], $point[1], 7, 7)
  }
  $sparkBrush.Dispose()
}

Save-Art -FileName 'get_started_profile.png' -DrawAction {
  param($g, $w, $h)

  Draw-Background `
    -Graphics $g `
    -Width $w `
    -Height $h `
    -TopLeft (New-Color 7 18 46) `
    -BottomRight (New-Color 16 121 151) `
    -GlowA (New-Color 20 184 166 96) `
    -GlowB (New-Color 249 115 22 84)

  Draw-PortalCore -Graphics $g -Source $portalCrop -X 540 -Y 176 -Width 520 -Height 660
  Draw-OrbitalRing `
    -Graphics $g `
    -X 468 `
    -Y 708 `
    -Width 680 `
    -Height 198 `
    -Color (New-Color 249 115 22 126) `
    -Stroke 10
  Draw-OrbitalRing `
    -Graphics $g `
    -X 416 `
    -Y 94 `
    -Width 760 `
    -Height 916 `
    -Color (New-Color 255 255 255 54) `
    -Stroke 4

  Draw-GlassCard -Graphics $g -X 132 -Y 230 -Width 300 -Height 188 -Tint (New-Color 59 34 246 48)
  Draw-GlassCard -Graphics $g -X 120 -Y 462 -Width 334 -Height 220 -Tint (New-Color 20 184 166 42)
  Draw-GlassCard -Graphics $g -X 1158 -Y 254 -Width 312 -Height 196 -Tint (New-Color 249 115 22 42)
  Draw-GlassCard -Graphics $g -X 1130 -Y 504 -Width 338 -Height 214 -Tint (New-Color 59 34 246 44)

  $badgeBrush = New-Object System.Drawing.SolidBrush (New-Color 255 255 255 178)
  foreach ($circle in @(
    @(1040, 168, 28), @(1098, 216, 18), @(466, 116, 22), @(512, 150, 14), @(320, 760, 16)
  )) {
    $g.FillEllipse($badgeBrush, $circle[0], $circle[1], $circle[2], $circle[2])
  }
  $badgeBrush.Dispose()
}

Save-Art -FileName 'get_started_connection.png' -DrawAction {
  param($g, $w, $h)

  Draw-Background `
    -Graphics $g `
    -Width $w `
    -Height $h `
    -TopLeft (New-Color 10 17 46) `
    -BottomRight (New-Color 41 98 255) `
    -GlowA (New-Color 59 34 246 94) `
    -GlowB (New-Color 20 184 166 88)

  Draw-PortalCore -Graphics $g -Source $portalCrop -X 562 -Y 188 -Width 500 -Height 640
  Draw-OrbitalRing `
    -Graphics $g `
    -X 440 `
    -Y 746 `
    -Width 726 `
    -Height 192 `
    -Color (New-Color 20 184 166 142) `
    -Stroke 11
  Draw-OrbitalRing `
    -Graphics $g `
    -X 366 `
    -Y 126 `
    -Width 876 `
    -Height 886 `
    -Color (New-Color 255 255 255 42) `
    -Stroke 5

  Draw-OpportunityNodes -Graphics $g -CenterX 812 -CenterY 530
  Draw-GlassCard -Graphics $g -X 132 -Y 330 -Width 274 -Height 176 -Tint (New-Color 20 184 166 38)
  Draw-GlassCard -Graphics $g -X 1184 -Y 336 -Width 286 -Height 182 -Tint (New-Color 59 34 246 42)

  $accentBrush = New-Object System.Drawing.SolidBrush (New-Color 249 115 22 176)
  $g.FillEllipse($accentBrush, 218, 278, 22, 22)
  $g.FillEllipse($accentBrush, 1368, 280, 22, 22)
  $accentBrush.Dispose()
}

$portalCrop.Dispose()
