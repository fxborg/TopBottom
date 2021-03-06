//+------------------------------------------------------------------+
//|                                                     htflines.mq5 |
//| HTF Lines                                 Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_buffers 2
#property indicator_plots  2
#property indicator_chart_window

#property indicator_type1 DRAW_NONE

#property indicator_color1 clrTomato
#property indicator_width1 2

#property indicator_type2 DRAW_NONE
#property indicator_color2 clrMediumSlateBlue
#property indicator_width2 2
//+------------------------------------------------------------------+
//| CStatus                                                            |
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
   int               m_h1_;
   int               m_h2_;
   int               m_l1_;
   int               m_l2_;

public:
   void              CStatus(){};                   // constructor
   void             ~CStatus(){};                   // destructor
   void              Init()
     {
      m_lastbar_time=0;    // Time of opening last bar   
      m_htf_bar_time=0;    // Time of opening last bar   
      m_high=NULL;
      m_low=NULL;
      m_high_pos=NULL;
      m_low_pos=NULL;
      m_h1=NULL;
      m_h2=NULL;
      m_l1=NULL;
      m_l2=NULL;
      m_h1_=NULL;
      m_h2_=NULL;
      m_l1_=NULL;
      m_l2_=NULL;

     }
   datetime LastBarTime() { return m_lastbar_time;}
   void LastBarTime(datetime v) { m_lastbar_time=v;}
   datetime HtfBarTime() { return m_htf_bar_time;}
   void HtfBarTime(datetime v) { m_htf_bar_time=v;}
   double High() { return m_high;}
   double Low() { return m_low;}
   int HighPos() { return m_high_pos;}
   int LowPos() { return m_low_pos;}
   void High(int i,double v) {m_high_pos=i; m_high=v;}
   void Low(int i,double v) { m_low_pos=i; m_low=v;}

   void GetLow(int &l1,int &l2)
     {
      l1=m_l1;
      l2=m_l2;
     }
   void SetLow(int l1,int l2)
     {
      m_l1=l1;
      m_l2=l2;
     }

   void GetHigh(int &h1,int &h2)
     {
      h1=m_h1;
      h2=m_h2;
     }
   void SetHigh(int h1,int h2)
     {
      m_h1=h1;
      m_h2=h2;
     }
   //---
   void GetLow2(int &l1,int &l2)
     {
      l1=m_l1_;
      l2=m_l2_;
     }
   void SetLow2(int l1,int l2)
     {
      m_l1_=l1;
      m_l2_=l2;
     }

   void GetHigh2(int &h1,int &h2)
     {
      h1=m_h1_;
      h2=m_h2_;
     }
   void SetHigh2(int h1,int h2)
     {
      m_h1_=h1;
      m_h2_=h2;
     }

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

input ENUM_TIMEFRAMES InpTF=PERIOD_H4; // Timeframe;
input int InpOID=1; //  Object ID
input int  InpShowLine=1;    //Show Line (1:show ,0:hide)  

//---- will be used as indicator buffers
double TOP[];
double BTM[];
double HZ[];
double LZ[];

CStatus Status;
CBuffer BtmBuffer;
CBuffer TopBuffer;

//---- declaration of global variables
int WinNo=ChartWindowFind();
int min_rates_total=2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point
   if(InpShowLine==0)
     {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_NONE);
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_NONE);
     }
   else
     {
      PlotIndexSetInteger(0,PLOT_DRAW_TYPE,DRAW_SECTION);
      PlotIndexSetInteger(1,PLOT_DRAW_TYPE,DRAW_SECTION);
     }
//--- indicator buffers
   int i=0;

   SetIndexBuffer(i++,TOP,INDICATOR_DATA);
   SetIndexBuffer(i++,BTM,INDICATOR_DATA);
   SetIndexBuffer(i++,HZ,INDICATOR_DATA);
   SetIndexBuffer(i++,LZ,INDICATOR_DATA);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(2,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(3,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---
   Status.Init();
   BtmBuffer.Init(100);
   TopBuffer.Init(100);

//---
   ObjectDeleteByName(StringFormat("TL_%d",InpOID));

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
      //---
      TOP[bar]=EMPTY_VALUE;
      BTM[bar]=EMPTY_VALUE;
      //---
      if(Status.LastBarTime()==time[bar])
        {
         continue;
        }

      Status.LastBarTime(time[bar]);
      //---
      int period_seconds=PeriodSeconds(InpTF);                     // Number of seconds in current chart period
      datetime new_time=time[bar]/period_seconds*period_seconds;
      //---
      if(Status.High()==NULL || high[i]>Status.High()) Status.High(i,high[i]);
      if(Status.Low()==NULL || low[i]<Status.Low()) Status.Low(i,low[i]);
      //---
      if(Status.HtfBarTime()!=new_time)
        {
         //---
         Status.HtfBarTime(new_time);

         double High=Status.High();
         double Low =Status.Low();
         int HighPos=Status.HighPos();
         int LowPos =Status.LowPos();
         Status.High(i,high[i]);
         Status.Low(i,low[i]);
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
            if(l1!=NULL)
              {
               BtmBuffer.Add(l1,low[l1]);
               BTM[l1]=low[l1];
              }
           }
         //---
         if(HighPos>_h2)
           {
            int h1=_h1;
            int h2=_h2;
            set_vertex(high,HighPos,-1,h1,h2);
            Status.SetHigh(h1,h2);
            if(h1!=NULL)
              {
               TopBuffer.Add(h1,high[h1]);
               TOP[h1]=high[h1];
              }
            //---
           }
         //---
        }
      //---
      if(BtmBuffer.GetIndex(1)!=NULL)
        {

         int l1= BtmBuffer.GetIndex(1);
         int l2= BtmBuffer.GetIndex(0);
         int span=(l2-l1);
         if(span>0 && l2<i)
           {
            double slope=((low[l2]-low[l1])/span) *(i-l2);
            drawTrend(InpOID,1,clrMediumSlateBlue,l1,low[l1],i,low[l2]+slope,time,STYLE_SOLID,2);
           }
        }

      //---
      if(TopBuffer.GetIndex(1)!=NULL)
        {

         int h1= TopBuffer.GetIndex(1);
         int h2= TopBuffer.GetIndex(0);
         int span=(h2-h1);
         if(span>0 && h2<i)
           {
            double slope=((high[h2]-high[h1])/span) *(i-h2);
            drawTrend(InpOID,2,clrTomato,h1,high[h1],i,high[h2]+slope,time,STYLE_SOLID,2);
           }
        }

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
void drawTrend(const int oid,int no,
               const color clr,const int x0,const double y0,const int x1,const double y1,
               const datetime &time[],const ENUM_LINE_STYLE style,const int width)
  {

   if(-1<ObjectFind(0,StringFormat("TL_%d_%d",oid,no)))
     {
      ObjectMove(0,StringFormat("TL_%d_%d",oid,no),0,time[x0],y0);
      ObjectMove(0,StringFormat("TL_%d_%d",oid,no),1,time[x1],y1);
     }
   else
     {
      ObjectCreate(0,StringFormat("TL_%d_%d",oid,no),OBJ_TREND,WinNo,time[x0],y0,time[x1],y1);
      ObjectSetInteger(0,StringFormat("TL_%d_%d",oid,no),OBJPROP_COLOR,clr);
      ObjectSetInteger(0,StringFormat("TL_%d_%d",oid,no),OBJPROP_STYLE,style);
      ObjectSetInteger(0,StringFormat("TL_%d_%d",oid,no),OBJPROP_WIDTH,width);
      ObjectSetInteger(0,StringFormat("TL_%d_%d",oid,no),OBJPROP_RAY_RIGHT,true);
     }
  }
//+------------------------------------------------------------------+

//+------------------------------------------------------------------+
//|                                                                  |
//+------------------------------------------------------------------+
void ObjectDeleteByName(string prefix)
  {
   int total=ObjectsTotal(0),
   length=StringLen(prefix);
   for(int i=total-1; i>=0; i--)
     {
      string objName=ObjectName(0,i);
      if(StringSubstr(objName,0,length)==prefix)
        {
         ObjectDelete(0,objName);
        }
     }
  }
//+------------------------------------------------------------------+
