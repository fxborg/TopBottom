//+------------------------------------------------------------------+
//|                                               first_brakeout.mq5 |
//| first_brakeout                            Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.05"

#property indicator_buffers 21
#property indicator_plots  19
#property indicator_chart_window

#property indicator_type1 DRAW_ARROW
#property indicator_color1 clrRed
#property indicator_width1 2

#property indicator_type2 DRAW_ARROW
#property indicator_color2 clrDodgerBlue
#property indicator_width2 1

#property indicator_type3 DRAW_ARROW
#property indicator_color3 clrRed
#property indicator_width3 1

#property indicator_type4 DRAW_ARROW
#property indicator_color4 clrDodgerBlue
#property indicator_width4 1

#property indicator_type5 DRAW_ARROW
#property indicator_color5 clrRed
#property indicator_width5 1

#property indicator_type6 DRAW_ARROW
#property indicator_color6 clrDodgerBlue
#property indicator_width6 1

#property indicator_type7 DRAW_ARROW
#property indicator_color7 clrRed
#property indicator_width7 1

#property indicator_type8 DRAW_ARROW
#property indicator_color8 clrDodgerBlue
#property indicator_width8 1

#property indicator_type9 DRAW_NONE
#property indicator_color9 clrGold
#property indicator_width9 2

#property indicator_type10 DRAW_LINE
#property indicator_color10 clrTomato
#property indicator_width10 1

#property indicator_type11 DRAW_LINE
#property indicator_color11 clrPowderBlue
#property indicator_width11 1

#property indicator_type12 DRAW_LINE
#property indicator_color12 clrTomato
#property indicator_width12 1

#property indicator_type13 DRAW_LINE
#property indicator_color13 clrPowderBlue
#property indicator_width13 1

#property indicator_type14 DRAW_LINE
#property indicator_color14 clrTomato
#property indicator_width14 1

#property indicator_type15 DRAW_LINE
#property indicator_color15 clrPowderBlue
#property indicator_width15 1

#property indicator_type16 DRAW_LINE
#property indicator_color16 clrTomato
#property indicator_width16 1

#property indicator_type17 DRAW_LINE
#property indicator_color17 clrPowderBlue
#property indicator_width17 1

#property indicator_type18 DRAW_LINE
#property indicator_color18 clrTomato
#property indicator_width18 1

#property indicator_type19 DRAW_LINE
#property indicator_color19 clrPowderBlue
#property indicator_width19 1
//+------------------------------------------------------------------+
//| CSignal                                                          |
//+------------------------------------------------------------------+
class CSignal
  {
protected:

   int               m_sig,m_brake_pos,m_prev_pos,m_1st_pos,m_2nd_pos,m_3rd_pos,m_min_pos,m_max_pos;
   double            m_min,m_max;
public:
   void              CSignal(){};                   // constructor
   void             ~CSignal(){};                   // destructor
   void              Init()
     {
      m_sig=0; m_brake_pos=NULL;m_prev_pos=2; m_1st_pos=NULL;  m_2nd_pos=NULL;  m_3rd_pos=NULL;
      m_min_pos=NULL;  m_max_pos=NULL; m_min=NULL; m_max=NULL;
     }
   void              Begin(int a,int b, int sig){ Init(); m_1st_pos=a; m_brake_pos=b; m_sig=sig;}
   void              Exit()                     { int a=m_brake_pos;Init(); m_prev_pos = a;}
   int               Sig()                      { return m_sig;}
   int               GetBrakePos()              { return m_brake_pos;}
   int               Get1stPos()                { return m_1st_pos;}
   int               Get2ndPos()                { return m_2nd_pos;}
   void              Set2ndPos(int i)           { m_2nd_pos=i; m_min_pos=NULL; m_min=NULL;m_max_pos=NULL;m_max=NULL; }
   int               Get3rdPos()                { return m_3rd_pos;}
   void              Set3rdPos(int i)           { m_3rd_pos=i; m_min_pos=NULL;m_min=NULL;m_max_pos=NULL;m_max=NULL; }
   void              UpdateMax(int i,double v)  { if(m_max==NULL || v>m_max){m_max=v; m_max_pos=i;}}
   int               GetMaxPos()                { return m_max_pos;}
   void              UpdateMin(int i,double v)  { if(m_min==NULL || v<m_min){m_min=v; m_min_pos=i;}}
   int               GetMinPos()                { return m_min_pos;}
   int               GetPrevPos()               { return m_prev_pos;}
  };
//+------------------------------------------------------------------+
//| CStatus                                                          |
//+------------------------------------------------------------------+
class CStatus
  {
protected:
   datetime          m_lastbar_time;   // Open time of the last bar 
   datetime          m_htf_bar_time;   // Open time of the last bar 
   double            m_high;
   double            m_low;
   int               m_high_pos;
   int               m_low_pos;
   int               m_h1;
   int               m_h2;
   int               m_l1;
   int               m_l2;
   int               m_support_pos;
   int               m_resist_pos;
   double            m_support_slope;
   double            m_resist_slope;
   int               m_support_id;
   int               m_resist_id;

public:
   void              CStatus(){};                   // constructor
   void             ~CStatus(){};                   // destructor
   void              Init()
     {
      m_lastbar_time  =0;    // Time of opening last bar   
      m_htf_bar_time  =0;    // Time of opening last bar   
      m_h1            =NULL;
      m_h2            =NULL;
      m_l1            =NULL;
      m_l2            =NULL;
      m_support_pos   =NULL;
      m_resist_pos    =NULL;
      m_support_slope =NULL;
      m_resist_slope  =NULL;
      m_support_id    =0;
      m_resist_id     =0;
     }
   //---
   datetime          LastBarTime()             { return m_lastbar_time;}
   void              LastBarTime(datetime v)   { m_lastbar_time=v;}
   //---
   datetime          HtfBarTime()              { return m_htf_bar_time;}
   void              HtfBarTime(datetime v)    { m_htf_bar_time=v;}
   //---
   int               ResistPos()               { return m_resist_pos;}
   void              ResistPos(int v)          { m_resist_pos=v;}
   int               SupportPos()              { return m_support_pos;}
   void              SupportPos(int v)         { m_support_pos=v;}
   //---
   double            ResistSlope()             { return m_resist_slope;}
   void              ResistSlope(double v)     { m_resist_slope=v;}
   double            SupportSlope()            { return m_support_slope;}
   void              SupportSlope(double v)    { m_support_slope=v;}
   //---
   void              GetLow(int &l1,int &l2)   { l1=m_l1; l2=m_l2;}
   void              SetLow(int l1,int l2)     { m_l1=l1; m_l2=l2;}
   //---
   void              GetHigh(int &h1,int &h2)  { h1=m_h1; h2=m_h2;}
   void              SetHigh(int h1,int h2)    { m_h1=h1; m_h2=h2;}
   //---
   void              AddSupportId()            { m_support_id=(m_support_id+1)%5; }
   int               SupportId()               { return m_support_id;}
   void              AddResistId()             { m_resist_id=(m_resist_id+1)%5; }
   int               ResistId()                { return m_resist_id;}

  };
//+------------------------------------------------------------------+
//| CBuffer                                                          |
//+------------------------------------------------------------------+
class CBuffer
  {
protected:
   int               m_size;
   int               m_index[];
   double            m_data[];
   int               m_last_pos;
public:
   void              CBuffer(){};                   // constructor
   void             ~CBuffer(){};                   // destructor
   void              Init(const int sz)
     {
      m_size=sz;
      m_last_pos=0;
      ArrayResize(m_index,m_size);
      ArrayResize(m_data,m_size);
      ArrayFill(m_index,0,m_size,NULL);
      ArrayFill(m_data,0,m_size,NULL);
     }
   int Size() { return m_size;}
   double GetValue(const int pos) const
     {
      if(pos < 0 && pos >= m_size) return (NULL);
      return ( m_data [((m_size + ((m_last_pos-pos)-1)) % m_size)]);
     }
   int GetIndex(const int pos) const
     {
      if(pos < 0 && pos >= m_size) return (NULL);
      return ( m_index [((m_size + ((m_last_pos-pos)-1)) % m_size)]);
     }
   void Add(const int index,const double value)
     {
      int pos=(m_size+(m_last_pos-1))%m_size;

      if(m_index[pos]==index)
        {
         m_data[pos]=value;
        }
      else
        {
         m_data[m_last_pos]=value;
         m_index[m_last_pos]=index;
         m_last_pos=(m_last_pos+1)%m_size;
        }
     }
  };

//+------------------------------------------------------------------+

//--- input parameters

input ENUM_TIMEFRAMES InpTF=PERIOD_M30; // Timeframe;
input int  InpEMAPeriod=20;    //EMA Period  
input int  InpLookBack=20;    //Look Back Period  

double EmaAlpha=2.0/(InpEMAPeriod+1.0);

//---- will be used as indicator buffers
double SUPPORT_BK[];
double RESIST_BK[];
double EMA[];
double DN1[];
double UP1[];
double DN2[];
double UP2[];
double DN3[];
double UP3[];
double BUY[];
double SELL[];
double SUPPORT1[];
double SUPPORT2[];
double SUPPORT3[];
double SUPPORT4[];
double SUPPORT5[];
double RESIST1[];
double RESIST2[];
double RESIST3[];
double RESIST4[];
double RESIST5[];

CSignal UpSignal;
CSignal DnSignal;
CStatus Status;
CBuffer BtmBuffer;
CBuffer TopBuffer;
int HTFLength=int(PeriodSeconds(InpTF)/PeriodSeconds(PERIOD_CURRENT));

//---- declaration of global variables
int min_rates_total=InpLookBack+HTFLength+10;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
//--- indicator buffers
   int i=0;

   SetIndexBuffer(i++,SELL,INDICATOR_DATA);
   SetIndexBuffer(i++,BUY,INDICATOR_DATA);
   SetIndexBuffer(i++,DN1,INDICATOR_DATA);
   SetIndexBuffer(i++,UP1,INDICATOR_DATA);
   SetIndexBuffer(i++,DN2,INDICATOR_DATA);
   SetIndexBuffer(i++,UP2,INDICATOR_DATA);
   SetIndexBuffer(i++,DN3,INDICATOR_DATA);
   SetIndexBuffer(i++,UP3,INDICATOR_DATA);
   SetIndexBuffer(i++,EMA,INDICATOR_DATA);
   SetIndexBuffer(i++,RESIST1,INDICATOR_DATA);
   SetIndexBuffer(i++,SUPPORT1,INDICATOR_DATA);
   SetIndexBuffer(i++,RESIST2,INDICATOR_DATA);
   SetIndexBuffer(i++,SUPPORT2,INDICATOR_DATA);
   SetIndexBuffer(i++,RESIST3,INDICATOR_DATA);
   SetIndexBuffer(i++,SUPPORT3,INDICATOR_DATA);
   SetIndexBuffer(i++,RESIST4,INDICATOR_DATA);
   SetIndexBuffer(i++,SUPPORT4,INDICATOR_DATA);
   SetIndexBuffer(i++,RESIST5,INDICATOR_DATA);
   SetIndexBuffer(i++,SUPPORT5,INDICATOR_DATA);
   SetIndexBuffer(i++,RESIST_BK,INDICATOR_CALCULATIONS);
   SetIndexBuffer(i++,SUPPORT_BK,INDICATOR_CALCULATIONS);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(4,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(5,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(6,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(7,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(8,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(9,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(10,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(11,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(12,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(13,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(14,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(15,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(16,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(17,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(18,PLOT_EMPTY_VALUE,EMPTY_VALUE);

   PlotIndexSetInteger(2,PLOT_ARROW,140);
   PlotIndexSetInteger(3,PLOT_ARROW,140);
   PlotIndexSetInteger(4,PLOT_ARROW,141);
   PlotIndexSetInteger(5,PLOT_ARROW,141);
   PlotIndexSetInteger(6,PLOT_ARROW,142);
   PlotIndexSetInteger(7,PLOT_ARROW,142);
   PlotIndexSetInteger(2,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(3,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(4,PLOT_ARROW_SHIFT,10);
   PlotIndexSetInteger(5,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(6,PLOT_ARROW_SHIFT,-10);
   PlotIndexSetInteger(7,PLOT_ARROW_SHIFT,10);

//---
   Status.Init();
   UpSignal.Init();
   DnSignal.Init();
   BtmBuffer.Init(100);
   TopBuffer.Init(100);

//---

//---
   return(INIT_SUCCEEDED);
  }
//+------------------------------------------------------------------+
//| Custom indicator iteration function                              |
//+------------------------------------------------------------------+
int OnCalculate(const int rates_total,
                const int prev_calculated,
                const datetime &time[],
                const double &open[],
                const double &high[],
                const double &low[],
                const double &close[],
                const long &tick_volume[],
                const long &volume[],
                const int &spread[])
  {

//---
   int first;
   if(rates_total<=min_rates_total)
      return(0);
//---

//+----------------------------------------------------+
//|Set Median Buffeer                                |
//+----------------------------------------------------+
   int begin_pos=min_rates_total;

   first=begin_pos;
   if(first+1<prev_calculated) first=prev_calculated-2;

//---
   for(int bar=first; bar<rates_total && !IsStopped(); bar++)
     {
      //---
      int i=bar-1;
      //---
      if(bar==begin_pos)
        {
         Status.SetHigh(NULL,bar);
         Status.SetLow(NULL,bar);
        }
      //---
      //---
      //---
      int period_seconds=PeriodSeconds(PERIOD_CURRENT);                     // Number of seconds in current chart period
      datetime new_time=time[bar]/period_seconds*period_seconds;

      if(Status.LastBarTime()>=new_time)
        {
         continue;
        }

      EMA[bar]=EMPTY_VALUE;
      SUPPORT1[bar]=EMPTY_VALUE;
      RESIST1[bar]=EMPTY_VALUE;
      SUPPORT2[bar]=EMPTY_VALUE;
      RESIST2[bar]=EMPTY_VALUE;
      SUPPORT3[bar]=EMPTY_VALUE;
      RESIST3[bar]=EMPTY_VALUE;
      SUPPORT4[bar]=EMPTY_VALUE;
      RESIST4[bar]=EMPTY_VALUE;
      SUPPORT5[bar]=EMPTY_VALUE;
      RESIST5[bar]=EMPTY_VALUE;
      SUPPORT_BK[bar]=EMPTY_VALUE;
      RESIST_BK[bar]=EMPTY_VALUE;

      SELL[bar]=EMPTY_VALUE;
      BUY[bar]=EMPTY_VALUE;

      UP1[bar]=EMPTY_VALUE;
      DN1[bar]=EMPTY_VALUE;
      UP2[bar]=EMPTY_VALUE;
      DN2[bar]=EMPTY_VALUE;
      UP3[bar]=EMPTY_VALUE;
      DN3[bar]=EMPTY_VALUE;

      Status.LastBarTime(new_time);
      if(i==begin_pos) EMA[i]=close[i];
      else EMA[i]=EmaAlpha*close[i]+(1-EmaAlpha)*EMA[i-1];
      //---
      period_seconds=PeriodSeconds(InpTF);                     // Number of seconds in current chart period
      new_time=time[bar]/period_seconds*period_seconds;
      //---
      //---
      if(Status.HtfBarTime()!=new_time)
        {
         //---
         Status.HtfBarTime(new_time);
         int HighPos= ArrayMaximum(high,i-(HTFLength -1),HTFLength);
         int LowPos = ArrayMinimum(low,i-(HTFLength -1),HTFLength );
         double High=high[HighPos];
         double Low=low[LowPos];
         //---
         //---
         int _h1,_h2,_l1,_l2;
         Status.GetHigh(_h1,_h2);
         Status.GetLow(_l1,_l2);

         //---
         if(LowPos>_l2)
           {
            int l1=_l1;
            int l2=_l2;
            set_vertex(low,LowPos,1,l1,l2);
            Status.SetLow(l1,l2);
            if(l1!=NULL) BtmBuffer.Add(l1,low[l1]);
           }
         //---
         if(HighPos>_h2)
           {
            int h1=_h1;
            int h2=_h2;
            set_vertex(high,HighPos,-1,h1,h2);
            Status.SetHigh(h1,h2);
            if(h1!=NULL) TopBuffer.Add(h1,high[h1]);
            //---
           }
        }//--- <<< HTF BAR

      //---
      if(BtmBuffer.GetIndex(1)!=NULL)
        {
         //----
         int l1;
         double slope;
         calc_slope(low,BtmBuffer,1,slope,l1);
         //----
         if(slope!=NULL && slope>=0)
           {
            if(l1==Status.SupportPos() && Status.SupportSlope()==slope)
              {
               set_support(i,get_support(i-1)+slope);
              }
            else
              {
               //---
               double dmin=fmin(close[i],fmin(close[i-1],close[i-2]));
               if(dmin>low[l1]+slope)
                 {
                  //---
                  Status.AddSupportId();
                  Status.SupportPos(l1);
                  Status.SupportSlope(slope);
                  //---
                  for(int j=Status.SupportPos()-1;j<=l1;j++) set_support(j,EMPTY_VALUE);
                  //---
                  set_support(l1,low[l1]);
                  for(int j=l1+1;j<=i;j++)
                    {
                     set_support(j,get_support(j-1)+slope);
                    }

                 }
              }
           }
        }

      //---
      if(TopBuffer.GetIndex(2)!=NULL)
        {
         //----
         int h1;
         double slope;
         calc_slope(high,TopBuffer,1,slope,h1);
         //----
         if(slope!=NULL && slope<=0)
           {
            if(Status.ResistPos()==h1 && Status.ResistSlope()==slope)
              {
               set_resist(i,get_resist(i-1)+slope);
              }
            else
              {
               //---
               double dmax=fmax(close[i],fmax(close[i-1],close[i-2]));
               //---
               if(dmax<high[h1]+slope)
                 {
                  //---
                  Status.ResistPos(h1);
                  Status.ResistSlope(slope);
                  Status.AddResistId();

                  for(int j=Status.ResistPos()-1;j<=h1;j++) set_resist(j,EMPTY_VALUE);
                  set_resist(h1,high[h1]);
                  for(int j=h1+1;j<=i;j++)
                    {
                     set_resist(j,get_resist(j-1)+slope);
                    }
                 }
              }
           }
        }
      //----
      if(TopBuffer.GetIndex(2)==NULL)continue;
      if(BtmBuffer.GetIndex(2)==NULL)continue;
      double dmin=fmin(fmin(close[i-5],close[i-4]),close[i-3]);
      double dmax=fmax(fmax(close[i-5],close[i-4]),close[i-3]);

      //---
      if(UpSignal.Sig()!=1 && get_resist(i)!=EMPTY_VALUE)
        {
         if(dmin<get_resist(i-3) && high[i-1]>get_resist(i-1) && low[i]>get_resist(i))
           {
            RESIST_BK[i-2]=EMPTY_VALUE;
            RESIST_BK[i-1]= get_resist(i-1);
            RESIST_BK[i]=get_resist(i);
            int span=fmin(InpLookBack,(i-(UpSignal.GetPrevPos()-2)));
            int a=ArrayMinimum(low,i-(span -1),span);

            UpSignal.Begin(a, i, 1);
            UpSignal.UpdateMax(i,high[i]);
            UP1[a]=low[a];
           }
        }
      //---
      if(DnSignal.Sig()!=-1 && get_support(i)!=EMPTY_VALUE)
        {
         if(dmax>get_support(i-3) && low[i-1]<get_support(i-1) && high[i]<get_support(i))
           {
            SUPPORT_BK[i-2]=EMPTY_VALUE;
            SUPPORT_BK[i-1]=get_support(i-1);
            SUPPORT_BK[i]=get_support(i);
            int span=fmin(InpLookBack,(i-(DnSignal.GetPrevPos()-2)));
            int a=ArrayMaximum(high,i-(span -1),span);
            DnSignal.Begin(a, i, -1);
            DnSignal.UpdateMin(i,low[i]);
            DN1[a]=high[a];
           }
        }
      //---
      if(UpSignal.Sig() ==  1 && RESIST_BK[i-2]!=EMPTY_VALUE) RESIST_BK[i]=RESIST_BK[i-1]+(RESIST_BK[i-1]-RESIST_BK[i-2]);
      if(DnSignal.Sig() == -1 && SUPPORT_BK[i-2]!=EMPTY_VALUE) SUPPORT_BK[i]=SUPPORT_BK[i-1]+(SUPPORT_BK[i-1]-SUPPORT_BK[i-2]);

      if(UpSignal.Sig()==1 && 
         ((close[i]<RESIST_BK[i] && close[i-1]<RESIST_BK[i-1]) || 
         i-UpSignal.GetBrakePos()>InpLookBack))
        {
         UpSignal.Exit();
         RESIST_BK[i]=EMPTY_VALUE;
        }

      if(DnSignal.Sig()==-1 && 
         ((close[i]>SUPPORT_BK[i] && close[i-1]>SUPPORT_BK[i-1]) || 
         i-DnSignal.GetBrakePos()>InpLookBack))
        {
         DnSignal.Exit();
         SUPPORT_BK[i]=EMPTY_VALUE;
        }

      //---
      if(UpSignal.Sig()==1 && UpSignal.Get2ndPos()==NULL && UpSignal.Get3rdPos()==NULL)
        {
         UpSignal.UpdateMax(i,high[i]);
         int b=UpSignal.GetMaxPos();
         //---
         if((b==i-1 && low[i-1]<low[i-2]) || (b<i && low[i]<low[i-1]))
           {
            UpSignal.Set2ndPos(b);
            UpSignal.UpdateMin(i,low[i]);
            UP2[b]=high[b];
           }
        }
      //---
      if(DnSignal.Sig()==-1 && DnSignal.Get2ndPos()==NULL && DnSignal.Get3rdPos()==NULL)
        {
         DnSignal.UpdateMin(i,low[i]);
         int b=DnSignal.GetMinPos();
         //---
         if((b==i-1 && high[i-1]>high[i-2]) || (b<i && high[i]>high[i-1]))
           {
            DnSignal.Set2ndPos(b);
            DnSignal.UpdateMax(i,high[i]);
            DN2[b]=low[b];
           }
        }
      //---
      if(UpSignal.Sig()==1 && UpSignal.Get2ndPos()!=NULL && UpSignal.Get3rdPos()==NULL)
        {
         UpSignal.UpdateMin(i,low[i]);
         int a = UpSignal.Get1stPos();  // low
         int b = UpSignal.Get2ndPos();  // high
         int c = UpSignal.GetMinPos();  // low
         //---
         double ab=high[b]-low[a];
         double bc=high[b]-low[c];
         //--- Cancel Signal
         if(low[a]>close[c])
           {
            UpSignal.Exit();
            RESIST_BK[i]=EMPTY_VALUE;
           }
         //---
         if((c==i-1 && high[i-1]>high[i-2]) || (c<i && high[i]>high[i-1]))
           {
            if(bc>ab*0.1)
              {

               UpSignal.Set3rdPos(c);
               UpSignal.UpdateMax(i,high[i]);
               UP3[c]=low[c];
              }
           }
         //---
        }
      //---
      if(DnSignal.Sig()==-1 && DnSignal.Get2ndPos()!=NULL && DnSignal.Get3rdPos()==NULL)
        {
         DnSignal.UpdateMax(i,high[i]);
         int a = DnSignal.Get1stPos();  // high
         int b = DnSignal.Get2ndPos();  // low
         int c = DnSignal.GetMaxPos();  // high
         //---
         double ab=high[a]-low[b];
         double bc=high[c]-low[b];
         //--- Cancel Signal
         if(high[a]<close[c])
           {
            DnSignal.Exit();
            SUPPORT_BK[i]=EMPTY_VALUE;
           }
         //---
         if((c==i-1 && low[i-1]<low[i-2]) || (c<i && low[i]<low[i-1]))
           {
            if(bc>ab*0.1)
              {
               DnSignal.Set3rdPos(c);
               DnSignal.UpdateMin(i,low[i]);
               DN3[c]=high[c];

              }
           }
         //---
        }
      //---
     }

//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
void set_vertex(const double &price[],int i,int opt,int &x1,int &x2)
  {
//---
   double slope2=(price[i]-price[x2])/((i)-x2);
   double slope1=(x1!=NULL)?(price[x2]-price[x1])/(x2-x1) : NULL;
   double diff=(opt==1) ?  slope1-slope2 : slope2-slope1;

   if(x1==NULL)
     {
      if(price[i]>=price[x2])
         x2=i;
      else
        {
         x1=x2;
         x2=i;
        }
     }
   else if(diff>=0)
     {
      x2=i;
     }
   else
     {
      x1=x2;
      x2=i;
     }
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double cross(const int ox,double oy,
             const int ax,double ay,
             const int bx,double by)
  {
   return ((ax - ox) * (by - oy) - (ay - oy) * (bx - ox));
  }
//+------------------------------------------------------------------+

void set_support(const int i,const double v)
  {

   if(Status.SupportId()==0)SUPPORT5[i]=v;
   else if(Status.SupportId()==1)SUPPORT1[i]=v;
   else if(Status.SupportId()==2)SUPPORT2[i]=v;
   else if(Status.SupportId()==3)SUPPORT3[i]=v;
   else if(Status.SupportId()==4)SUPPORT4[i]=v;

  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void set_resist(const int i,const double v)
  {
   if(Status.ResistId()==0)RESIST5[i]=v;
   else if(Status.ResistId()==1)RESIST1[i]=v;
   else if(Status.ResistId()==2)RESIST2[i]=v;
   else if(Status.ResistId()==3)RESIST3[i]=v;
   else if(Status.ResistId()==4)RESIST4[i]=v;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_support(const int i)
  {
   if(Status.SupportId()==0)return SUPPORT5[i];
   else if(Status.SupportId()==1)return SUPPORT1[i];
   else if(Status.SupportId()==2)return SUPPORT2[i];
   else if(Status.SupportId()==3)return SUPPORT3[i];
   else if(Status.SupportId()==4)return SUPPORT4[i];
   else return EMPTY_VALUE;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
double get_resist(const int i)
  {
   if(Status.ResistId()==0)return RESIST5[i];
   else if(Status.ResistId()==1)return RESIST1[i];
   else if(Status.ResistId()==2)return RESIST2[i];
   else if(Status.ResistId()==3)return RESIST3[i];
   else if(Status.ResistId()==4)return RESIST4[i];
   else return EMPTY_VALUE;
  }
//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void calc_slope(const double  &price[],const CBuffer &buf,const int dir,double  &slope,int  &pos)
  {
// dir->( 1) ･･･ BtmBuffer
// dir->(-1) ･･･ TopBuffer
//---
   slope=NULL;
//---
   int p0= buf.GetIndex(0);
   int p1= buf.GetIndex(1);
   int p2= buf.GetIndex(2);
//---
   if(cross(p2,price[p2],p1,price[p1],p0,price[p0])*dir>0)
     {
      slope=(price[p0]-price[p1])/(p0-p1);
      pos=p1;
      return;
     }
//---
   int jj=1;
   int to=p0;
   for(int j=1;j<=50;j++)
     {
      //---
      p0 = buf.GetIndex(j);
      p1 = buf.GetIndex(j+1);
      p2 = buf.GetIndex(j+2);
      //---
      if(p2==NULL)break;
      //---
      if(cross(p2,price[p2],p1,price[p1],p0,price[p0])*dir<0)
        {
         jj=j+1;
         break;
        }
      //---
     }

   if(jj>1)
     {
      double slope_max=NULL;
      int slope_from=NULL;
      for(int j=2;j<=jj;j++)
        {
         p1=buf.GetIndex(j);
         double temp=((price[to]-price[p1])/(to-p1));

         if(slope_max==NULL || (temp-slope_max)*dir>0)
           {
            slope_max=temp;
            slope_from=p1;
           }
        }

      slope=slope_max;
      pos=slope_from;
     }
//---
  }
//+------------------------------------------------------------------+
