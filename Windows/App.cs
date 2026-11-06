using System;
using System.IO;
using System.Diagnostics;
using System.Threading;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Markup;
using System.Windows.Threading;
using System.Security.Principal;
using System.Runtime.InteropServices;
using Forms=System.Windows.Forms;
namespace StayAwake {
static class Program {
 public static string Data=Path.Combine(Environment.GetFolderPath(Environment.SpecialFolder.LocalApplicationData),"MacStayAwake.Windows");
 public static string Journal=Path.Combine(Data,"power-session.xml");
 public static string Identity="Local\\MacStayAwake.Windows."+WindowsIdentity.GetCurrent().User.Value;
 public static PowerService Power=new PowerService(new NativePower(),Journal);
 public static void Log(string text){try{Directory.CreateDirectory(Data);File.AppendAllText(Path.Combine(Data,"app.log"),DateTime.Now.ToString("s")+" "+text+Environment.NewLine);}catch{}}
 public static void Locked(Action action){using(var gate=new Mutex(false,Identity+".power")){try{gate.WaitOne();}catch(AbandonedMutexException){}try{action();}finally{gate.ReleaseMutex();}}}
 [STAThread] public static int Main(string[] args){
  if(args.Length>0 && args[0]=="--watch"){
   try{var p=Process.GetProcessById(int.Parse(args[1]));if(p.StartTime.ToUniversalTime().Ticks!=long.Parse(args[2]))return 0;using(var ready=EventWaitHandle.OpenExisting(args[3]))ready.Set();p.WaitForExit();Locked(()=>Power.Restore());Log("watcher: recovery complete");return 0;}catch(Exception e){Log("watcher: "+e);return 1;}
  }
  bool created;using(var singleton=new Mutex(true,Identity+".main",out created)){
   if(!created){try{using(var e=EventWaitHandle.OpenExisting(Identity+".show"))e.Set();}catch{MessageBox.Show("Please wait for the application to start, then open it again.","Mac Stay Awake");}return 0;}
   using(var show=new EventWaitHandle(false,EventResetMode.AutoReset,Identity+".show")){
    try{Directory.CreateDirectory(Data);
     // Select software rendering before creating any WPF presentation source.
     // Laptop lid/display transitions and remote sessions can invalidate GPU surfaces.
     RenderOptions.ProcessRenderMode=System.Windows.Interop.RenderMode.SoftwareOnly;
     Log("render: SoftwareOnly");
     var app=new Application();app.ShutdownMode=ShutdownMode.OnExplicitShutdown;var window=new MainWindow(show);app.Run(window);return 0;}
    catch(Exception e){Log(e.ToString());MessageBox.Show(e.Message,"Mac Stay Awake");return 1;}
   }
  }
 }
}
sealed class MainWindow : Window {
 [DllImport("dwmapi.dll")] static extern int DwmSetWindowAttribute(IntPtr window,int attribute,ref int value,int size);
 Window ui;EventWaitHandle show;Forms.NotifyIcon tray;DispatcherTimer poll;bool active,busy,quitting,idleLidNoSleep;int lang=1,theme;DateTime checkedAt;string error="";bool watcherReady;
 string[] themes={"standardAppearance","frostedGlass","midnight","warmSand"};
 static Stream OpenResource(string name){var stream=System.Reflection.Assembly.GetExecutingAssembly().GetManifestResourceStream(name);if(stream==null)throw new FileNotFoundException("Missing embedded resource: "+name);return stream;}
 static System.Drawing.Icon TrayIcon(){using(var stream=OpenResource("AppIcon.ico"))using(var icon=new System.Drawing.Icon(stream))return (System.Drawing.Icon)icon.Clone();}
 string T(string key){return Strings.Text[key][lang];}
 T Find<T>(string name) where T:class{return ui.FindName(name) as T;}
 TextBlock Label(string n){return Find<TextBlock>(n);} Button Button(string n){return Find<Button>(n);}
 public MainWindow(EventWaitHandle show){
  this.show=show;
  SourceInitialized+=(sender,eventArgs)=>{var source=System.Windows.Interop.HwndSource.FromHwnd(new System.Windows.Interop.WindowInteropHelper(this).Handle);if(source!=null){source.CompositionTarget.RenderMode=System.Windows.Interop.RenderMode.SoftwareOnly;source.AddHook(DisplayMessage);}};
  var baseDir=AppDomain.CurrentDomain.BaseDirectory;
  using(var f=OpenResource("MainWindow.xaml"))ui=(Window)XamlReader.Load(f);
  Title=ui.Title;Width=ui.Width;Height=ui.Height;ResizeMode=ResizeMode.CanMinimize;WindowStartupLocation=WindowStartupLocation.CenterScreen;FontFamily=ui.FontFamily;FontSize=12;UseLayoutRounding=true;
  Resources=ui.Resources;var content=ui.Content;ui.Content=null;Content=content;SetResourceReference(BackgroundProperty,"Background");SetResourceReference(ForegroundProperty,"Primary");
  using(var icon=OpenResource("AppIcon.ico"))Icon=BitmapFrame.Create(icon,BitmapCreateOptions.PreservePixelFormat,BitmapCacheOption.OnLoad);
  using(var coffee=OpenResource("CoffeeMark.png"))Find<System.Windows.Shapes.Rectangle>("Logo").OpacityMask=new ImageBrush(BitmapFrame.Create(coffee,BitmapCreateOptions.PreservePixelFormat,BitmapCacheOption.OnLoad));
  try{var settings=File.ReadAllText(Path.Combine(Program.Data,"preferences.txt")).Split(',');lang=Math.Max(0,Math.Min(2,int.Parse(settings[0])));theme=Math.Max(0,Math.Min(3,int.Parse(settings[1])));}catch{}
  Button("Normal").Click+=async(s,e)=>await Normalize();Button("Toggle").Click+=async (s,e)=>await Change();Button("Refresh").Click+=async(s,e)=>await Refresh();Button("Menu").Click+=(s,e)=>OpenMenu();
  tray=new Forms.NotifyIcon{Icon=TrayIcon(),Text="Mac Stay Awake",Visible=true};tray.MouseClick+=(s,e)=>Dispatcher.BeginInvoke(new Action(()=>{if(e.Button==Forms.MouseButtons.Left)Reveal();else OpenMenu();}));
  Closing+=(s,e)=>{if(!quitting){e.Cancel=true;Hide();tray.ShowBalloonTip(2500,"Mac Stay Awake",lang==2?"Running in the notification area. Open the app again to show this window.":"程式仍在通知區運行；再次開啟程式即可顯示視窗。",Forms.ToolTipIcon.Info);}};
  var app=Application.Current;app.SessionEnding+=(s,e)=>{try{NativePower.SetThreadExecutionState(0x80000000);Program.Locked(()=>Program.Power.Restore());}catch(Exception ex){Program.Log(ex.ToString());}};
  var quitCommand=new System.Windows.Input.RoutedCommand();CommandBindings.Add(new System.Windows.Input.CommandBinding(quitCommand,async(s,e)=>await Quit()));InputBindings.Add(new System.Windows.Input.KeyBinding(quitCommand,new System.Windows.Input.KeyGesture(System.Windows.Input.Key.Q,System.Windows.Input.ModifierKeys.Control)));
  ApplyTheme();Render();
  poll=new DispatcherTimer{Interval=TimeSpan.FromMilliseconds(250)};int ticks=0;poll.Tick+=async(s,e)=>{if(show.WaitOne(0))Reveal();if(++ticks%20==0&&!busy&&(IsVisible||active))await Refresh();};poll.Start();
  Loaded+=async(s,e)=>{ApplyTheme();await Initialize();};
 }
 IntPtr DisplayMessage(IntPtr hwnd,int message,IntPtr wParam,IntPtr lParam,ref bool handled){
  // WM_DISPLAYCHANGE, WM_DWMCOMPOSITIONCHANGED, and resume power notifications.
  if(message==0x007E||message==0x031E||(message==0x0218&&(wParam.ToInt64()==7||wParam.ToInt64()==18))){
   Dispatcher.BeginInvoke(DispatcherPriority.Render,new Action(()=>{InvalidateVisual();var content=Content as UIElement;if(content!=null)content.InvalidateVisual();Program.Log("render: refreshed after display/power change");}));
  }
  return IntPtr.Zero;
 }
 async Task Initialize(){busy=true;Render();try{await Task.Run(()=>Program.Locked(()=>Program.Power.Restore()));watcherReady=await Task.Run(()=>StartWatcher());if(!watcherReady)throw new Exception("Recovery watcher could not start.");await Task.Run(()=>{Program.Power.Inspect();idleLidNoSleep=!Program.Power.AllowsLidSleep();});checkedAt=DateTime.Now;}catch(Exception e){error=e.Message;Program.Log(e.ToString());}finally{busy=false;Render();}}
 bool StartWatcher(){var p=Process.GetCurrentProcess();var name=Program.Identity+".ready."+p.Id;using(var ready=new EventWaitHandle(false,EventResetMode.AutoReset,name)){Process.Start(new ProcessStartInfo(p.MainModule.FileName,"--watch "+p.Id+" "+p.StartTime.ToUniversalTime().Ticks+" "+name){UseShellExecute=false,CreateNoWindow=true,WindowStyle=ProcessWindowStyle.Hidden});return ready.WaitOne(10000);}}
 void Reveal(){Show();if(WindowState==WindowState.Minimized)WindowState=WindowState.Normal;Activate();Topmost=true;Topmost=false;Program.Log("window: shown");}
 async Task Change(){if(busy)return;busy=true;error="";Render();try{
  if(active||Program.Power.HasSession){NativePower.SetThreadExecutionState(0x80000000);active=false;await Task.Run(()=>Program.Locked(()=>Program.Power.UseNormalMode()));idleLidNoSleep=false;}
  else {if(!watcherReady)throw new Exception("Recovery watcher unavailable. Restart the app.");if(NativePower.SetThreadExecutionState(0x80000001)==0)throw new Exception("Windows rejected the keep-awake request.");try{await Task.Run(()=>Program.Locked(()=>Program.Power.Enable()));active=true;}catch{NativePower.SetThreadExecutionState(0x80000000);throw;}}
  checkedAt=DateTime.Now;Program.Log("power: active="+active+"; "+Program.Power.Inspect());
 }catch(Exception e){error=e.Message;Program.Log(e.ToString());}finally{busy=false;Render();}}
 async Task Normalize(){if(busy)return;busy=true;error="";Render();try{NativePower.SetThreadExecutionState(0x80000000);active=false;await Task.Run(()=>Program.Locked(()=>Program.Power.UseNormalMode()));idleLidNoSleep=false;checkedAt=DateTime.Now;Program.Log("normal mode: "+Program.Power.Inspect());}catch(Exception e){error=e.Message;Program.Log(e.ToString());}finally{busy=false;Render();}}
 async Task Refresh(){if(busy)return;busy=true;Render();try{if(active){bool verified=false;await Task.Run(()=>Program.Locked(()=>verified=Program.Power.Verified()));if(!verified){NativePower.SetThreadExecutionState(0x80000000);active=false;await Task.Run(()=>Program.Locked(()=>Program.Power.Restore()));throw new Exception(lang==2?"Power settings changed. Closed-lid mode stopped.":"電源設定已變更，闔蓋運行已停止。");}}else{await Task.Run(()=>{Program.Power.Inspect();idleLidNoSleep=!Program.Power.AllowsLidSleep();});}checkedAt=DateTime.Now;error="";if(active)Program.Log("heartbeat: verified; network="+System.Net.NetworkInformation.NetworkInterface.GetIsNetworkAvailable());}catch(Exception e){error=e.Message;Program.Log(e.ToString());}finally{busy=false;Render();}}
 void Render(){bool normalWarning=!active&&idleLidNoSleep;bool warning=error.Length>0||normalWarning;Label("StatusTitle").Text=T(warning?(Program.Power.HasSession||normalWarning?"normalNotRestored":"statusUnknown"):active?"awakeMode":"normalMode");Label("StatusDetail").Text=T(warning?"unknownDetail":active?"awakeDetail":"normalDetail");Label("SleepLabel").Text="☾  "+T("preventSystemSleep");Label("CheckedLabel").Text="◷  "+T("lastChecked");Label("CheckedValue").Text=checkedAt==default(DateTime)?T("notChecked"):checkedAt.ToString("h:mm:ss tt");Label("StatusValue").Text="• "+T(warning?"unconfirmed":active?"enabled":"disabled");var color=(SolidColorBrush)Resources[active?"Success":"Secondary"];Label("StatusValue").Foreground=warning?Brushes.DarkOrange:color;Find<Border>("Pill").Background=new SolidColorBrush(Color.FromArgb(22,color.Color.R,color.Color.G,color.Color.B));SetButton(Button("Toggle"),busy?T("checking"):T(active||Program.Power.HasSession?"restoreNormal":"enableAwake"),true);Button("Toggle").IsEnabled=!busy;SetButton(Button("Refresh"),T(busy?"checking":"refresh"),false);Button("Refresh").IsEnabled=!busy;Button("Normal").Visibility=normalWarning?Visibility.Visible:Visibility.Collapsed;Button("Normal").Content=T("restoreNormal");Button("Normal").IsEnabled=!busy;Label("AutoLabel").Text=T("autoCheck");Label("ThemeName").Text=T(themes[theme]);Label("Error").Text=normalWarning?(lang==2?"Windows is still set to do nothing when the lid closes. Restore normal mode to enable lid sleep.":lang==0?"Windows 合盖仍不休眠。请恢复正常模式，启用合盖睡眠。":"Windows 闔蓋仍不睡眠。請恢復正常模式，啟用闔蓋睡眠。"):error;Label("Error").Visibility=warning?Visibility.Visible:Visibility.Collapsed;Button("Menu").ToolTip=T("appMenu");System.Windows.Automation.AutomationProperties.SetName(Button("Menu"),T("appMenu"));tray.Text="Mac Stay Awake — "+T(active?"enabled":"disabled");}
 void SetButton(Button button,string text,bool power){var row=new StackPanel{Orientation=Orientation.Horizontal};var icon=new System.Windows.Shapes.Path{Data=Geometry.Parse(power?"M7,0 L7,7 M3,2 A6,6 0 1 0 11,2":"M11,3 A5.5,5.5 0 1 0 12,9 M11,0 L11,4 L7,4"),Stroke=button.Foreground,StrokeThickness=1.5,Width=14,Height=14,Stretch=Stretch.Uniform,Margin=new Thickness(0,0,7,0),VerticalAlignment=VerticalAlignment.Center};row.Children.Add(icon);row.Children.Add(new TextBlock{Text=text,VerticalAlignment=VerticalAlignment.Center});button.Content=row;System.Windows.Automation.AutomationProperties.SetName(button,text);}
 void Save(){try{File.WriteAllText(Path.Combine(Program.Data,"preferences.txt"),lang+","+theme);}catch(Exception e){Program.Log(e.ToString());}}
 void OpenMenu(){var menu=new ContextMenu{Background=(Brush)Resources["Surface"],Foreground=(Brush)Resources["Primary"]};var appearance=new MenuItem{Header=T("appearance")};for(int i=0;i<4;i++){int value=i;var item=new MenuItem{Header=T(themes[i]),IsCheckable=true,IsChecked=i==theme};item.Click+=(s,e)=>{theme=value;ApplyTheme();Save();Render();};var row=new DockPanel{Width=160};var swatch=new System.Windows.Shapes.Ellipse{Width=17,Height=17,Stroke=Brushes.Gray,StrokeThickness=0.5,Fill=new LinearGradientBrush((Color)ColorConverter.ConvertFromString(new[]{"#FAFAFA","#91E8E8","#405485","#F7E0B3"}[i]),(Color)ColorConverter.ConvertFromString(new[]{"#ADADAD","#9CA8F5","#0F1729","#B07A4F"}[i]),45)};DockPanel.SetDock(swatch,Dock.Right);row.Children.Add(swatch);row.Children.Add(new TextBlock{Text=T(themes[i])});item.Header=row;System.Windows.Automation.AutomationProperties.SetName(item,T(themes[i]));appearance.Items.Add(item);}menu.Items.Add(appearance);var language=new MenuItem{Header=T("switchLanguage")};string[] names={"简体中文","繁體中文","English"};for(int i=0;i<3;i++){int value=i;var item=new MenuItem{Header=names[i],IsCheckable=true,IsChecked=i==lang};item.Click+=(s,e)=>{lang=value;Save();Render();};language.Items.Add(item);}menu.Items.Add(language);menu.Items.Add(new Separator());var quit=new MenuItem{Header=T("quit"),IsEnabled=!busy};quit.Click+=async(s,e)=>await Quit();menu.Items.Add(quit);menu.PlacementTarget=Button("Menu");menu.Placement=System.Windows.Controls.Primitives.PlacementMode.Top;menu.IsOpen=true;menu.Focus();}
 async Task Quit(){if(busy)return;busy=true;Render();try{NativePower.SetThreadExecutionState(0x80000000);active=false;await Task.Run(()=>Program.Locked(()=>Program.Power.Restore()));quitting=true;poll.Stop();tray.Visible=false;tray.Dispose();Application.Current.Shutdown();}catch(Exception e){error=e.Message;busy=false;Render();Reveal();}}
 static void Glow(Canvas canvas,double width,double height,double left,double top,string color,double opacity,double blur){var e=new System.Windows.Shapes.Ellipse{Width=width,Height=height,Fill=new SolidColorBrush((Color)ColorConverter.ConvertFromString(color)),Opacity=opacity,Effect=new System.Windows.Media.Effects.BlurEffect{Radius=blur}};Canvas.SetLeft(e,left);Canvas.SetTop(e,top);canvas.Children.Add(e);}
 void ApplyTheme(){string[][] colors={new[]{"#FFFFFF","#242424","#858585","#FFFFFF","#14000000","#007AFF","#FFFFFF","#34C759"},new[]{"#DCEBF7","#1F3352","#526682","#57FFFFFF","#C7FFFFFF","#3B5CBF","#FFFFFF","#1A6E4F"},new[]{"#0E1321","#EDF2FF","#9EADC9","#1F293D","#1FFFFFFF","#ABBDFF","#141F3B","#70E0B0"},new[]{"#FAF2DE","#453326","#7A634F","#FFFAEB","#307D5C3B","#7A4F36","#FFFFFF","#406B4A"}};string[] keys={"Background","Primary","Secondary","Surface","Border","Accent","ButtonText","Success"};for(int i=0;i<keys.Length;i++)Resources[keys[i]]=new SolidColorBrush((Color)ColorConverter.ConvertFromString(colors[theme][i]));if(theme>0){var gradient=new LinearGradientBrush();gradient.StartPoint=new Point(0,0);gradient.EndPoint=new Point(1,1);string[] starts={"#FFFFFF","#E9EEF0","#1A2438","#FAF2DE"};string[] ends={"#FFFFFF","#E7E9F7","#0E1321","#EBDCC2"};gradient.GradientStops.Add(new GradientStop((Color)ColorConverter.ConvertFromString(starts[theme]),0));gradient.GradientStops.Add(new GradientStop((Color)ColorConverter.ConvertFromString(ends[theme]),1));Resources["Background"]=gradient;}Label("StatusTitle").FontFamily=new FontFamily(theme==3?"Georgia":"Segoe UI");
 try{int dark=theme==2?1:0;DwmSetWindowAttribute(new System.Windows.Interop.WindowInteropHelper(this).Handle,20,ref dark,4);}catch{}
 var canvas=Find<Canvas>("Atmosphere");canvas.Children.Clear();if(theme==1){Glow(canvas,310,230,-110,-50,"#5ED6DB",0.42,48);Glow(canvas,280,320,220,122,"#A19EF5",0.35,56);}if(theme==2)Glow(canvas,300,300,30,-75,"#475EB3",0.24,70);
 var accent=((SolidColorBrush)Resources["Accent"]).Color;var faded=accent;faded.A=224;Button("Toggle").Background=new LinearGradientBrush(accent,faded,45);Button("Toggle").Effect=new System.Windows.Media.Effects.DropShadowEffect{Color=accent,Opacity=0.14,BlurRadius=8,ShadowDepth=3,Direction=270};}
}
}
