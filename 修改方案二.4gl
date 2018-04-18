FUNCTION t540_cs()
	   CLEAR FORM
	   IF NOT cl_null(g_argv1) THEN
              IF g_argv3 <> 'SUB' THEN       #NO:6961
		  LET g_wc = " pmm01 = '",g_argv1,"'"
              ELSE
		  LET g_wc = " 1=1 "         #NO:6961
              END IF
	   ELSE
              CONSTRUCT BY NAME g_wc ON                    # 螢幕上取條件
                  pmm01,pmm03,pmm04,pmm06,pmm09,pmm20,pmm45,pmm25,
                  pmm02,pmm12,pmm13,
                  pmm21,pmm43,pmm22,pmm42,pmmmksg,pmm40,pmm99, #No.7920 add
                  pmm18,pmm905,                                #No.7920 add
                  pmmuser,pmmgrup,pmmmodu,pmmdate,pmmacti
                  	
              IF INT_FLAG THEN LET INT_FLAG=0 RETURN END IF
              CALL t540_b_askkey()
              IF INT_FLAG THEN RETURN END IF
           END IF
     #20180105  begin
     IF g_paim06='1'  THEN #東莞
     	IF g_grup = '30210' OR g_grup = '31220' THEN
		 		CALL s_abc1(0,g_user,g_grup,0,'cpmt540','pmm01') RETURNING g_condition,g_s,g_ax,g_ax2,g_s2,g_condition2
		 		IF g_s='Y' THEN
		 			 LET g_wc=g_wc CLIPPED," AND pmm01[1,3] IN(",g_condition,")"
		 		END IF
		 		CALL s_abc1(0,g_user,g_grup,0,'cpmt540','pmm04') RETURNING g_condition,g_s,g_ax,g_ax2,g_s2,g_condition2
		 		IF g_ax2='Y' THEN
		 			 IF g_s2='Y' THEN
		 			 		LET g_wc2=g_wc2 CLIPPED,g_condition2
		 			 END IF
		 		END IF
		 		{#檢查部門所有
		 		IF g_ax='Y' THEN
		 			 LET g_wc=g_wc CLIPPED," AND pmigrup='",g_grup,"'"
		 		END IF
		 		}
		 	END IF
		 END IF
		 #20180105 end

	   #資料權限的檢查
	   IF g_priv2='4' THEN                           #只能使用自己的資料
		  LET g_wc = g_wc clipped," AND pmmuser = '",g_user,"'"
	   END IF
	   IF g_priv3='4' THEN                           #只能使用相同群的資料
            LET g_wc = g_wc clipped," AND pmmgrup MATCHES '",g_grup CLIPPED,"*'"
	   END IF
	   IF g_argv2 = '0' THEN      #已開立
              LET g_wc = g_wc clipped," AND pmm25 IN ('X','0','1','2','6','9','S','R','W','O') "   
	   END IF
	   IF g_argv2 = '1' THEN      #已核淮
		  LET g_wc = g_wc clipped," AND pmm25 IN ('1') "   
	   END IF
	   IF g_argv2 = '2' THEN      #已發出        
		  LET g_wc = g_wc clipped," AND pmm25 IN ('2') "   
	   END IF
	   IF g_argv3 = 'SUB' THEN 
		  LET g_wc = g_wc clipped," AND pmm02 = 'SUB' "  
	   ELSE 
		  LET g_wc = g_wc clipped," AND pmm02 not IN ('SUB') "   
	   END IF

	   IF g_wc2=' 1=1 ' THEN 
               IF g_argv3='SUB' THEN  #NO:6961
		               LET g_sql="SELECT DISTINCT pmm_file.ROWID,pmm01 ",   #No:9600
                             "  FROM pmm_file,pmn_file ", #組合出SQL指令
                             " WHERE pmm01=pmn01(+) AND ", g_wc CLIPPED
                   IF NOT cl_null(g_argv4)  THEN   #NO:6961
                      LET g_sql= g_sql CLIPPED," AND pmn41='",g_argv4,"' ",   
                                               " ORDER BY pmm01 "
                   ELSE
                      LET g_sql=g_sql CLIPPED ," ORDER BY pmm01 " 
                   END IF
               ELSE
		           LET g_sql="SELECT ROWID,pmm01 FROM pmm_file ", #組合出SQL指令
                             " WHERE ",g_wc CLIPPED,
                             " ORDER BY pmm01"
               END IF
	   ELSE
		   LET g_sql="SELECT DISTINCT pmm_file.ROWID,pmm01 FROM pmm_file,pmn_file ",   #No:9600
                          " WHERE ",g_wc CLIPPED," AND ",g_wc2 CLIPPED,
                          "   AND pmm01 = pmn01(+)",
                          " ORDER BY pmm01"
	   END IF

	   PREPARE t540_prepare FROM g_sql           # RUNTIME 編譯
	   DECLARE t540_cs                         # SCROLL CURSOR
		SCROLL CURSOR WITH HOLD FOR t540_prepare
       IF g_argv3='SUB' THEN
	        IF g_wc2=' 1=1 ' THEN
                   LET g_sql= "SELECT COUNT(DISTINCT pmm01) ",
                              "  FROM pmm_file,pmn_file ",
#20111228 begin
                              " WHERE pmm02='SUB' AND pmn01(+)=pmm01 ",
#20111228 end
                              "   AND ",g_wc CLIPPED
                   IF NOT cl_null(g_argv4)  THEN   #NO:6961
                      LET g_sql= g_sql CLIPPED," AND pmn41='",g_argv4,"' "   
                   END IF
          ELSE
                   LET g_sql= "SELECT COUNT(DISTINCT pmm01) ",
                              "  FROM pmm_file,pmn_file",
#20111228 begin
                              " WHERE pmm01 = pmn01(+) AND pmm02='SUB' ",
#20111228 end
                              "   AND ",g_wc CLIPPED,
                              "   AND ",g_wc2
	        END IF
       ELSE
	       IF g_wc2=' 1=1 ' THEN
                LET g_sql= "SELECT COUNT(*) FROM pmm_file",
                              " WHERE pmm02 != 'SUB' AND ",g_wc CLIPPED
         ELSE
               LET g_sql= "SELECT COUNT(DISTINCT pmm01) FROM pmm_file,pmn_file",
#20111228 begin
                          " WHERE pmm01 = pmn01(+)",
#20111228 end                          
                          "  AND pmm02 != 'SUB' AND ",g_wc CLIPPED," AND ",
                          g_wc2
	       END IF
	   END IF
    PREPARE t540_precount FROM g_sql
    DECLARE t540_count CURSOR FOR t540_precount
END FUNCTION

FUNCTION t540_b_askkey()
	   CONSTRUCT g_wc2 ON pmn02,pmn24,pmn25,pmn65,pmn41,pmn42,pmn04,pmn16,
                              pmn041,pmn07,pmn20,pmn68,pmn69,pmn31,pmn64,
                              pmn63,pmn33,pmn34,pmn43,pmn431,pmn122,pmn06,ima021    #20110221
           FROM s_pmn[1].pmn02,s_pmn[1].pmn24,s_pmn[1].pmn25,s_pmn[1].pmn65,
                s_pmn[1].pmn41,s_pmn[1].pmn42,s_pmn[1].pmn04,s_pmn[1].pmn16,
                s_pmn[1].pmn041,s_pmn[1].pmn07,s_pmn[1].pmn20,
                s_pmn[1].pmn68,s_pmn[1].pmn69,s_pmn[1].pmn31,
		s_pmn[1].pmn64,s_pmn[1].pmn63,s_pmn[1].pmn33,s_pmn[1].pmn34,
		s_pmn[1].pmn43,s_pmn[1].pmn431,s_pmn[1].pmn122,s_pmn[1].pmn06,s_pmn[1].ima021    #20110221
		
		
		
END FUNCTION