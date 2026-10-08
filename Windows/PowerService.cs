using System;
using System.IO;
using System.Runtime.InteropServices;
using System.ComponentModel;
using System.Xml.Serialization;
namespace StayAwake {
public interface IPower {
 Guid Active(); uint Read(Guid plan, bool ac); void Write(Guid plan, bool ac, uint value); void Apply(Guid plan);
}
public sealed class NativePower : IPower {
 static Guid group=new Guid("4f971e89-eebd-4455-a8de-9e59040e7347"), lid=new Guid("5ca83367-6e45-459f-a27b-476b1d01c936");
 [DllImport("powrprof.dll")] static extern uint PowerGetActiveScheme(IntPtr key,out IntPtr plan);
 [DllImport("kernel32.dll")] static extern IntPtr LocalFree(IntPtr p);
 [DllImport("powrprof.dll")] static extern uint PowerReadACValueIndex(IntPtr k,ref Guid p,ref Guid g,ref Guid s,out uint v);
 [DllImport("powrprof.dll")] static extern uint PowerReadDCValueIndex(IntPtr k,ref Guid p,ref Guid g,ref Guid s,out uint v);
 [DllImport("powrprof.dll")] static extern uint PowerWriteACValueIndex(IntPtr k,ref Guid p,ref Guid g,ref Guid s,uint v);
 [DllImport("powrprof.dll")] static extern uint PowerWriteDCValueIndex(IntPtr k,ref Guid p,ref Guid g,ref Guid s,uint v);
 [DllImport("powrprof.dll")] static extern uint PowerSetActiveScheme(IntPtr k,ref Guid p);
 [DllImport("kernel32.dll",SetLastError=true)] public static extern uint SetThreadExecutionState(uint flags);
 static void Check(uint n){if(n!=0)throw new Win32Exception((int)n);}
 public Guid Active(){IntPtr p;Check(PowerGetActiveScheme(IntPtr.Zero,out p));try{return (Guid)Marshal.PtrToStructure(p,typeof(Guid));}finally{LocalFree(p);}}
 public uint Read(Guid p,bool ac){uint v;Check(ac?PowerReadACValueIndex(IntPtr.Zero,ref p,ref group,ref lid,out v):PowerReadDCValueIndex(IntPtr.Zero,ref p,ref group,ref lid,out v));return v;}
 public void Write(Guid p,bool ac,uint v){Check(ac?PowerWriteACValueIndex(IntPtr.Zero,ref p,ref group,ref lid,v):PowerWriteDCValueIndex(IntPtr.Zero,ref p,ref group,ref lid,v));}
 public void Apply(Guid p){if(Active()==p)Check(PowerSetActiveScheme(IntPtr.Zero,ref p));}
}
public class Session {public Guid Plan; public uint AC; public uint DC;}
public sealed class PowerService {
 readonly IPower power; readonly string path; public bool HasSession {get{return File.Exists(path);}}
 public PowerService(IPower power,string path){this.power=power;this.path=path;}
 Session Load(){using(var f=File.OpenRead(path))return (Session)new XmlSerializer(typeof(Session)).Deserialize(f);}
 void Save(Session s){Directory.CreateDirectory(Path.GetDirectoryName(path));using(var f=new FileStream(path,FileMode.CreateNew,FileAccess.Write,FileShare.None)){new XmlSerializer(typeof(Session)).Serialize(f,s);f.Flush(true);}}
 public void Enable(){
  if(HasSession)throw new InvalidOperationException("Restore the previous session first.");
  var p=power.Active();var s=new Session{Plan=p,AC=power.Read(p,true),DC=power.Read(p,false)};
  Save(s);
  try{if(power.Active()!=p)throw new InvalidOperationException("Power plan changed.");power.Write(p,true,0);power.Write(p,false,0);power.Apply(p);if(!Verified())throw new InvalidOperationException("The lid settings could not be verified.");}
  catch {Restore();throw;}
 }
 public bool Verified(){if(!HasSession)return false;var s=Load();return power.Active()==s.Plan && power.Read(s.Plan,true)==0 && power.Read(s.Plan,false)==0;}
 public void Restore(){
  if(!HasSession)return;var s=Load();
  // Preserve nonzero values changed by the user while this application was active.
  RestoreOne(s.Plan,true,s.AC);RestoreOne(s.Plan,false,s.DC);power.Apply(s.Plan);File.Delete(path);
 }
 void RestoreOne(Guid p,bool ac,uint original){if(power.Read(p,ac)!=0)return;power.Write(p,ac,original);if(power.Read(p,ac)!=original)throw new InvalidOperationException("The original lid setting could not be restored.");}
 public bool AllowsLidSleep(){var p=power.Active();return power.Read(p,true)!=0 && power.Read(p,false)!=0;}
 public void UseNormalMode(){
  // An explicit normal-mode action must not restore a pre-existing Do Nothing baseline.
  // Recovery and failed-enable rollback still restore the exact captured values.
  Restore();
  var p=power.Active();var ac=power.Read(p,true);var dc=power.Read(p,false);
  if(ac!=0 && dc!=0)return;
  // Persist the desired correction before writes so recovery/retry can finish it.
  Save(new Session{Plan=p,AC=ac==0?1:ac,DC=dc==0?1:dc});
  Restore();
  if(power.Active()!=p || !AllowsLidSleep())throw new InvalidOperationException("Normal lid behavior could not be verified.");
 }
 public string Inspect(){var p=power.Active();return "AC="+power.Read(p,true)+"; DC="+power.Read(p,false)+"; Plan="+p;}
}
}
