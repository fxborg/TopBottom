//+------------------------------------------------------------------+
//|                                                    minilines.mq5 |
//| mini lines                                Copyright 2016, fxborg |
//|                                   http://fxborg-labo.hateblo.jp/ |
//+------------------------------------------------------------------+
#property copyright "Copyright 2016, fxborg"
#property link      "http://fxborg-labo.hateblo.jp/"
#property version   "1.00"

#property indicator_buffers 4
#property indicator_plots  2
#property indicator_chart_window

#property indicator_type1 DRAW_LINE

#property indicator_color1 clrTomato
#property indicator_width1 2

#property indicator_type2 DRAW_LINE
#property indicator_color2 clrMediumSlateBlue
#property indicator_width2 2
//+------------------------------------------------------------------+
//| CStatus                                                            |
//+------------------------------------------------------------------+
class CStatus
  {
protected:
   datetime          m_lastbar_time;   // Open time of the last bar 
   double            m_slope;
   int               m_x1;
   int               m_x2;
   int               m_x3;
   int               m_turn;
   int               m_turn_pos;

public:
   void              CStatus(){};                   // constructor
   void             ~CStatus(){};                   // destructor
   void              Init()
     {
      m_lastbar_time=0;    // Time of opening last bar   
      m_x1=NULL;
      m_x2=NULL;
      m_x3=NULL;
      m_turn=NULL;
      m_turn_pos=NULL;
     }
   datetime LastBarTime() { return m_lastbar_time;}
   void LastBarTime(datetime v) { m_lastbar_time=v;}

   int Turn() { return m_turn;}
   int TurnPos() { return m_turn_pos;}

   void SetTurn(int p,int v)
     {
      if(m_turn_pos==p)return;
      m_turn_pos=p;
      m_turn=v;
      InitVertex();
     }
   void InitVertex()
     {
      m_x1=NULL;
      m_x2=NULL;
      m_x3=NULL;
     }

   void GetVertex(int &x1,int &x2,int &x3)
     {
      x1=m_x1;
      x2=m_x2;
      x3=m_x3;

     }
   void SetVertex(int x1,int x2,int x3)
     {
      if(x2==x3)return;
      m_x1=x1;
      m_x2=x2;
      m_x3=x3;

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

input int InpBars1=2; // Bars 1;
input int InpBars2=10; // Bars 2;

//---- will be used as indicator buffers
double TOP[];
double BTM[];


CStatus Status;
CBuffer BtmBuffer;
CBuffer TopBuffer;

//---- declaration of global variables

int min_rates_total=InpBars1+2;
//+------------------------------------------------------------------+
//| Custom indicator initialization function                         |
//+------------------------------------------------------------------+
int OnInit()
  {
//---- Initialization of variables of data calculation starting point

//--- indicator buffers
   int i=0;

   SetIndexBuffer(i++,TOP,INDICATOR_DATA);
   SetIndexBuffer(i++,BTM,INDICATOR_DATA);

   PlotIndexSetDouble(0,PLOT_EMPTY_VALUE,EMPTY_VALUE);
   PlotIndexSetDouble(1,PLOT_EMPTY_VALUE,EMPTY_VALUE);

//---
   Status.Init();
   BtmBuffer.Init(100);
   TopBuffer.Init(100);
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
   int i,first;
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
   for(i=first; i<rates_total && !IsStopped(); i++)
     {
      if(Status.LastBarTime()==time[i])continue;
      Status.LastBarTime(time[i]);

      TOP[i]=EMPTY_VALUE;
      BTM[i]=EMPTY_VALUE;
      //---

      if(i==begin_pos)
        {
         // only first time
         Status.SetTurn(i,0);
         continue;
        }

      if(Status.Turn()==0)
        {
         double higher   = fmax(high[i-2],high[i-3]);
         double lower    = fmin(low[i-2],low[i-3]);
         bool isOutSide  = (high[i-2] <  high[i-1] && low[i-2] >  low[i-1]);
         bool isUpClose  = high[i-2] < close[i-1];
         bool isDnClose  = low[i-2] > close[i-1];
         bool isHigh     = high[i-2] < high[i-1];
         bool isLow      = low[i-2] > low[i-1];

         if((isOutSide && higher<close[i-1]) || (!isOutSide && higher<high[i-1]))
           {
            Status.SetTurn(i-1,1);

            if(low[i-2]>low[i-3])
               Status.SetVertex(NULL,i-3,i-1);
            else
               Status.SetVertex(NULL,i-2,i-1);

           }
         if((isOutSide && lower>close[i-1]) || (!isOutSide && lower>low[i-1]))
           {
            Status.SetTurn(i-1,-1);
            if(high[i-2]<high[i-3])
               Status.SetVertex(NULL,i-3,i-1);
            else
               Status.SetVertex(NULL,i-2,i-1);

           }
        }
      int _x1,_x2,_x3;
      Status.GetVertex(_x1,_x2,_x3);

      //---
      if(Status.Turn()!=NULL && Status.TurnPos()<=i-1)
        {
         int x1=_x1;
         int x2=_x2;
         int x3=_x3;
         //---
         //---
         if(Status.Turn()==1)
           {
            if(i-1==x3)continue;
            double slope3=(low[i-1]-low[x3])/((i-1)-x3);
            double slope2=(x2!=NULL)?(low[x3]-low[x2])/(x3-x2) : NULL;

            if(x2==NULL)
              {
               if(low[i-1]>=low[x3])
                  x3=i-1;
               else
                 {
                  x2=x3;
                  x3=i-1;
                 }
              }
            else if(slope3<=slope2)
              {
               x3=i-1;
              }
            else
              {
               x1=x2;
               x2=x3;
               x3=i-1;
              }
            Status.SetVertex(x1,x2,x3);

           }
         //---
         else if(Status.Turn()==-1)
         //---
           {
            if(i-1==x3)continue;
            double slope3=(high[i-1]-high[x3])/((i-1)-x3);

            double slope2=(x2!=NULL)?(high[x3]-high[x2])/(x3-x2) : NULL;

            if(x2==NULL)
              {
               if(high[i-1]<=high[x3])
                  x3=i-1;
               else
                 {
                  x2=x3;
                  x3=i-1;
                 }
              }
            else if(slope3>=slope2)
              {
               x3=i-1;
              }
            else
              {
               x1=x2;
               x2=x3;
               x3=i-1;
              }
            Status.SetVertex(x1,x2,x3);

            //---
           }
        }
      int x1,x2,x3;
      Status.GetVertex(x1,x2,x3);
      //---

      if(x2!=NULL && Status.Turn()==1) BtmBuffer.Add(x2,low[x2]);
      if(x2!=NULL && Status.Turn()==-1)TopBuffer.Add(x2,high[x2]);

      if(Status.TurnPos()<i-4)
        {

         //---
         if(Status.Turn()==1)
           {
            int from_x=NULL;
            double slope=NULL;
            for(int j=1;j<BtmBuffer.Size();j++)
              {
               int p=BtmBuffer.GetIndex(j);
               if(p<Status.TurnPos())break;
               if(x2==p)continue;
               double tmp=(low[x2]-low[p])/(x2-p);
               if(slope==NULL || tmp>slope)
                 {
                  slope=tmp;
                  from_x=p;
                 }
              }
            if(slope!=NULL && slope>0)
              {

               double b=low[x2];
               BTM[Status.TurnPos()]=EMPTY_VALUE;
               for(int j=Status.TurnPos()+1;j<=i-1;j++)
                 {
                  if(j<i-11)BTM[j]=EMPTY_VALUE;
                  else BTM[j]=slope*(j-x2)+b;
                 }
              }

           }
         if(Status.Turn()==-1)
           {
            int from_x=NULL;
            double slope=NULL;
            for(int j=1;j<TopBuffer.Size();j++)
              {
               int p=TopBuffer.GetIndex(j);
               if(p<Status.TurnPos())break;
               if(x2==p)continue;
               double tmp=(high[x2]-high[p])/(x2-p);
               if(slope==NULL || tmp<slope)
                 {
                  slope=tmp;
                  from_x=p;
                 }
              }
            if(slope!=NULL && slope<0)
              {
               double b=high[x2];
               TOP[Status.TurnPos()]=EMPTY_VALUE;
               for(int j=Status.TurnPos()+1;j<=i-1;j++)
                 {
                  if(j<i-11)TOP[j]=EMPTY_VALUE;
                  else TOP[j]=slope*(j-x2)+b;
                 }
              }

           }
        }

      if(Status.Turn()!=-1 && BTM[i-2]!=EMPTY_VALUE && BTM[i-3]!=EMPTY_VALUE)
        {
         BTM[i-1]=BTM[i-2]+(BTM[i-2]-BTM[i-3]);
        }
      if(Status.Turn()!=1 && TOP[i-2]!=EMPTY_VALUE && TOP[i-3]!=EMPTY_VALUE)
         TOP[i-1]=TOP[i-2]+(TOP[i-2]-TOP[i-3]);

      if(Status.Turn()==1)
        {
         double lower=low[Status.TurnPos()];
         if(BTM[i-2]!=EMPTY_VALUE && BTM[i-1]!=EMPTY_VALUE)
           {
            if(BTM[i-2]>low[i-2] && BTM[i-1]>high[i-1]) Status.SetTurn(i-1,0);

           }
         else if(lower>low[i-2] && lower>high[i-1])Status.SetTurn(i-1,-1);
        }
      if(Status.Turn()==-1)
        {
         double upper=high[Status.TurnPos()];
         if(TOP[i-2]!=EMPTY_VALUE && TOP[i-1]!=EMPTY_VALUE)
           {
            if(TOP[i-2]<high[i-2] && TOP[i-1]<low[i-1]) Status.SetTurn(i-1,0);

           }
         else  if(upper<high[i-2] && upper<low[i-1])Status.SetTurn(i-1,1);
        }

     }

//----    

   return(rates_total);
  }
//+------------------------------------------------------------------+
