Function ConvertTo-UpperCase {
    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param(
        #String to process.
        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipeline
        )]
        $InputObject,
    
        #Capitalizes the letter at this position in the character array.
        [Parameter(
            Position = 0,
            ParameterSetName = 'Index'
        )]
        $Index = 0,
    
        #Capitalizes all instances of this character.
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = 'Char'
        )]
        $Pattern,
    
        #Forces all existing capitals that do not meet the criteria to lower case.
        [Parameter( Position = 1)]
        [Switch]$Force
    ) 
    Process{
        if($Force){
            $ScriptBlock = {"$($InputObject[$_])".ToLower()}
        }else{
            $ScriptBlock = {"$($InputObject[$_])"}
        }
        $Characters = 0..($InputObject.Length-1)|
            Foreach-Object{
                Switch($_){
                {   #Condition
                    (&$ScriptBlock) -match $Pattern -and $Pattern
                }{  #Expression
                    (&$ScriptBlock).ToUpper()
                    break
                }{  #Condition
                    $Index -contains $_ -and !$Pattern
                }{  #Expression
                    (&$ScriptBlock).ToUpper()
                    break
                }  
                Default{
                    &$ScriptBlock
                }
            }
        }
        $Characters -join ''
    } 
}
Function Set-LowerCase {
    [CmdletBinding(DefaultParameterSetName = 'Index')]
    Param(
        #String to process.
        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipeline
        )]
        $InputObject,
    
        #Sets  the letter at this position in the character array to lower.
        [Parameter(
            Position = 0,
            ParameterSetName = 'Index'
        )]
        $Index = 0,
    
        #Sets all instances of this patter to lowercase.
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = 'Char'
        )]
        $Pattern,
    
        #Forces all existing capitals that do not meet the criteria to upper case.
        [Parameter( Position = 1)]
        [Switch]$Force
    ) 
    Process{
        if($Force){
            $ScriptBlock = {"$($InputObject[$_])".ToUpper()}
        }else{
            $ScriptBlock = {"$($InputObject[$_])"}
        }
        $Characters = 0..($InputObject.Length-1)|
            Foreach-Object{
                Switch($_){
                {   #Condition
                    (&$ScriptBlock) -match $Pattern -and $Pattern
                }{  #Expression
                    (&$ScriptBlock).ToLower()
                    break
                }{  #Condition
                    $Index -contains $_ -and !$Pattern
                }{  #Expression
                    (&$ScriptBlock).ToLower()
                    break
                }  
                Default{
                    &$ScriptBlock
                }
            }
        }
        $Characters -join ''
    } 
}
Function Join-String {
    [CmdletBinding()]
    Param(
        [Parameter(
            Position = 0
        )][Alias(
            "Joint"
        )][String]
        $Insert = '',

        [Parameter(
            Mandatory,
            Position = 1,
            ValueFromPipeline
        )][String]
        $InputObject
    ) 
    Begin{
        $Strings =@()
    }
    Process{
        $InputObject | 
            ForEach-Object{
                $Strings += $_
            }
    } 
    End{
        $Strings -join $Insert
    }
}
Function Split-String {
    [CmdletBinding()]
    Param(
        [Parameter(
            Mandatory,
            Position = 0
        )]$Pattern,

        [Parameter(
            ValueFromPipeline,
            Mandatory
        )][String[]]
        $InputObject,

        [Switch]
        $Keep
    )
    Process{
        if($Keep){
            $Index = 0
            [Regex]::Matches($InputObject,$Pattern)|
                ForEach-Object {
                    "$InputObject"[$Index..($_.Index)] -join ''
                    $Index = $_.Index + 1
                }
        }else{
            $InputObject -split $Pattern
        }
    }
}
Function Get-Match{
    [CmdletBinding(DefaultParameterSetName='Pipeline')]
    Param(
        [Parameter(
            Mandatory,
            Position = 0,
            ParameterSetName = 'Pipeline'
        )][Parameter(
            Mandatory,
            Position = 1,
            ParameterSetName = 'Path' 
        )][Alias("Regex")]
        [Alias("Expression")]
        <# Not yet implemented.
        [ArgumentCompleter({
            param($commandName, $parameterName, $wordToComplete, $commandAst, $fakeBoundParameters)
            
            Import-Csv ((($commandName|Get-Command).Module.Path | Split-Path -Parent) + '\RegularExpressions.csv')|Where-Object{
                $_[0] -like "$wordToComplete*"
            }|
                ForEach-Object{
                    [System.Management.Automation.CompletionResult]::new(
                        '"'+$_.Expression +'"',
                        $_.Name,
                        "ParameterValue",
                        ($_.Expression,$_.ToolTip -join "`n")
                    )
                }
        })]#>
        $Pattern,
        [Parameter(
            Mandatory,
            Position = 1,
            ParameterSetName = 'Pipeline',
            ValueFromPipeline
        )][Object[]]
        $InputObject,
        [Parameter(
            Mandatory,
            Position=0,
            ParameterSetName = 'Path'
        )][String[]]
        $Path,
        [Switch]
        $AsObject
    )
    Begin {
        $ErrorActionPreference = 'Stop'
        try {
            [Regex[]]$Pattern = $Pattern
        }
        catch {
            Throw $_
        }
        $ErrorActionPreference = 'Continue'
    }
    Process {
        if($Path){
            $InputObject = $Path | 
                Get-Item
        }
        $Strings = Switch($InputObject){
            {   #Condition
                $_ -is [String] -or $_ -is [String[]]
            }{  #Expression
                $_
            }{  #Condition
                $_ -is [System.IO.DirectoryInfo]
            }{  #Expression
                $_ | Get-ChildItem -file | 
                    Get-Content
            }{  #Condition
                $_ -is [System.IO.FileInfo]
            }{  #Expression
                $_ | Get-Content
            }{  #Condition
                $_ -is [Microsoft.PowerShell.Commands.HtmlWebResponseObject]
            }{  #Expression
                $_.Content
            }
        }
        if($Strings){
            $Pattern.Matches($Strings) | 
                ForEach-Object {
                    if($AsObject){
                        $_
                    }Else{
                        $_.Value
                    }
                }
        }
    }
}
Function ConvertTo-UrlEncoded{
    [CmdletBinding()]
    Param(
        #String to process.
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline
        )][String[]]
        $InputObject
    )
    Process{
        $InputObject |
            Foreach-Object{
                [System.Web.httpUtility]::UrlEncode($_)
            }
    }
}
Function ConvertFrom-UrlEncoded{
    [CmdletBinding()]
    Param(
        #String to process.
        [Parameter(
            Mandatory,
            Position = 0,
            ValueFromPipeline
        )][String[]]
        $InputObject
    )
    Process{
        $InputObject |
            Foreach-Object{
                [System.Web.httpUtility]::UrlDecode($_)
            }
    }
}
Function Add-String {
    [CmdletBinding()]
    param (
        [Parameter(
            Position=0
        )][String]
        $Prepend,
        [Parameter(
            Position=1
        )][String]
        $Append,
        [Parameter(
            Position=2,
            ValueFromPipeLine
        )][String]
        $InputObject
    )
    Process{
        "$Prepend$InputObject$Append"
    }
}
$MyInvocation.MyCommand.ScriptBlock.Ast.EndBlock.Statements | 
    Where-Object{$_.Extent.Text -match '^\s*Function'}|
    ForEach-Object {
        Export-ModuleMember -Function $_.Name
    }