package KxJRT;

import java.util.ArrayList;

/**
 * A StringTokenizer class that handle empty tokens.
 * @see KxJRT.KxSmartTokenizer
 */   
public class KxSmartTokenizer 
{
  private ArrayList mTokens;
  private int       mCurrent;
  
  public KxSmartTokenizer (String string, String delimiter)
  {
    mTokens  = new ArrayList();
    mCurrent = 0;
    
    java.util.StringTokenizer lTokenizer =
      new java.util.StringTokenizer (string, delimiter, true);

    boolean wasDelimiter = true;
    boolean isDelimiter  = false;    
    
    while (lTokenizer.hasMoreTokens()) {
      String lToken = lTokenizer.nextToken();

      isDelimiter = lToken.equals (delimiter);
      
      if (wasDelimiter)
        mTokens.add (isDelimiter ? "" : lToken);
      else if (!isDelimiter)
        mTokens.add (lToken);

      wasDelimiter = isDelimiter;
    }

    if (isDelimiter) mTokens.add ("");
  }


  public int countTokens()
  {
    return mTokens.size();
  }

  
  public boolean hasMoreTokens()
  {
    return mCurrent < mTokens.size();
  }


  public boolean hasMoreElements()
  {
    return hasMoreTokens();
  }


  public Object nextElement()
  {
    return nextToken();
  }


  public String nextToken()
  {
    String lToken = (String) mTokens.get (mCurrent);
    mCurrent++;
    return lToken;
  }
}

