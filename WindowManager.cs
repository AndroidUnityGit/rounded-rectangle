using UnityEngine;
using System.Runtime.InteropServices;
using System;
using System.Drawing;
using System.Windows.Forms;
using System.Diagnostics;
using UnityEngine;
using System.IO;

public class WindowManager : MonoBehaviour
{
    private static WindowManager instance;

    public static WindowManager Instance
    {
        get
        {
            return instance;
        }
    }
    // Use this for initialization
    [SerializeField]
    private Material m_Material;
    private struct MARGINS
    {
        public int cxLeftWidth;
        public int cxRightWidth;
        public int cyTopHeight;
        public int cyBottomHeight;
    }
    // Define function signatures to import from Windows APIs
    [DllImport("user32.dll")]
    private static extern IntPtr GetActiveWindow();
    [DllImport("user32.dll")]
    private static extern int SetWindowLong(IntPtr hWnd, int nIndex, uint dwNewLong);
    [DllImport("Dwmapi.dll")]
    private static extern uint DwmExtendFrameIntoClientArea(IntPtr hWnd, ref MARGINS margins);

    public delegate bool WNDENUMPROC(IntPtr hwnd, uint lParam);
    [DllImport("user32.dll", SetLastError = true)]
    public static extern bool EnumWindows(WNDENUMPROC lpEnumFunc, uint lParam);

    [DllImport("user32.dll", SetLastError = true)]
    public static extern IntPtr GetParent(IntPtr hWnd);
    [DllImport("user32.dll")]
    public static extern uint GetWindowThreadProcessId(IntPtr hWnd, ref uint lpdwProcessId);


    [DllImport("kernel32.dll")]
    public static extern void SetLastError(uint dwErrCode);


    // Definitions of window styles
    const int GWL_STYLE = -16;
    const uint WS_POPUP = 0x80000000;
    const uint WS_VISIBLE = 0x10000000;
    const int GWL_EXSTYLE = -20;
    const uint WS_EX_LAYERED = 0x00080000;
    const uint WS_EX_TRANSPARENT = 0x00000020;
    const uint WS_EX_TOOLWINDOW = 0x00000080;

    public const int width = 1920;
    public const int height = 1080;

    private string LogPath;
    void Start()
    {

        LogPath = UnityEngine.Application.dataPath + "/Log.txt";

        SetWindowScreen(width, height);
        var margins = new MARGINS() { cxLeftWidth = -1 };
        var hwnd = GetProcessWnd();
        SetWindowLong(hwnd, GWL_STYLE, WS_POPUP | WS_VISIBLE);
        SetWindowLong(hwnd, GWL_EXSTYLE, WS_EX_LAYERED | WS_EX_TRANSPARENT | WS_EX_TOOLWINDOW);  //鼠标的穿透 WS_EX_TRANSPARENT，图标不显示在任务栏WS_EX_TOOLWINDOW
        DwmExtendFrameIntoClientArea(hwnd, ref margins);

        //设置托盘图标
        SetTrayIcon();

    }

    private NotifyIcon trayIcon;
    private ContextMenuStrip trayMenu;
    private string pathIcon;
  
    /// <summary>
    /// 让应用程序图标显示在托盘中，
    /// </summary>
    private void SetTrayIcon()
    {

        try
        {
            pathIcon = UnityEngine.Application.dataPath + "/Test/Test.ico";
            trayMenu = new ContextMenuStrip(); //添加右击应用图标弹出退出应用的操作选项
            trayMenu.Items.Add("退出", null, (object sender, EventArgs e) =>
            {
                trayIcon.Visible = false;
                trayMenu.Dispose();
                trayIcon.Dispose();
                UnityEngine.Application.Quit();
            });

            trayIcon = new NotifyIcon();
            trayIcon.Text = UnityEngine.Application.productName;
            trayIcon.Icon = new Icon(pathIcon);
            trayIcon.ContextMenuStrip = trayMenu;
            trayIcon.Visible = true;
        }
        catch (Exception e)
        {
            string s = "出错了： " + e.ToString();
            File.WriteAllText(LogPath, s);
           
        }
      
    }

   

    void SetWindowScreen(int width, int height)
    {
        //Screen.fullScreen = true;
        UnityEngine.Screen.SetResolution(width, height, false);
    }

    void OnRenderImage(RenderTexture from, RenderTexture to)
    {
        UnityEngine.Graphics.Blit(from, to, m_Material);
    }

    public static IntPtr GetProcessWnd()
    {
        IntPtr ptrWnd = IntPtr.Zero;
        uint pid = (uint)Process.GetCurrentProcess().Id;  // 当前进程 ID  

        bool bResult = EnumWindows(new WNDENUMPROC(delegate (IntPtr hwnd, uint lParam)
        {
            uint id = 0;

            if (GetParent(hwnd) == IntPtr.Zero)
            {
                GetWindowThreadProcessId(hwnd, ref id);
                if (id == lParam)    // 找到进程对应的主窗口句柄  
                {
                    ptrWnd = hwnd;   // 把句柄缓存起来  
                    SetLastError(0);    // 设置无错误  
                    return false;   // 返回 false 以终止枚举窗口  
                }
            }

            return true;

        }), pid);
        return (!bResult && Marshal.GetLastWin32Error() == 0) ? ptrWnd : IntPtr.Zero;
    }

}
