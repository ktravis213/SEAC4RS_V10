!------------------------------------------------------------------------------
!                  GEOS-Chem Global Chemical Transport Model                  !
!------------------------------------------------------------------------------
!BOP
!
! !MODULE: diag_oh_mod
!
! !DESCRIPTION: Module DIAG\_OH\_MOD contains routines and variables to 
!  archive OH mass and air mass concentrations.  These are then used to print 
!  out the mass-weighted mean OH concentration in 1e5 molec/cm3.  This is a 
!  metric of how certain chemisry simulations are performing.
!\\
!\\
! !INTERFACE:
!
      MODULE DIAG_OH_MOD
!
! !USES:
!
      USE PRECISION_MOD    ! For GEOS-Chem Precision (fp)

      IMPLICIT NONE
      PRIVATE
!
! !PUBLIC MEMBER FUNCTIONS:
! 
      PUBLIC  :: CLEANUP_DIAG_OH
      PUBLIC  :: DO_DIAG_OH
      PUBLIC  :: DO_DIAG_OH_CH4
      PUBLIC  :: INIT_DIAG_OH
      PUBLIC  :: PRINT_DIAG_OH
!
! !REVISION HISTORY:
!  (1 ) Remove code for obsolete CO-OH simulation (bmy, 6/24/05)
!  20 Aug 2013 - R. Yantosca - Removed "define.h", this is now obsolete
!  12 Nov 2014 - M. Yannetti - Added PRECISION_MOD
!  19 Dec 2014 - R. Yantosca - Need to keep some variables as REAL*8
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !PRIVATE TYPES:
! 
      ! Scalars
      LOGICAL               :: DO_SAVE_OH

      ! Arrays 
      REAL(f8), ALLOCATABLE :: OH_MASS(:,:,:)
      REAL(f8), ALLOCATABLE :: AIR_MASS(:,:,:)
      REAL(f8), ALLOCATABLE :: OH_LOSS(:,:,:)
      REAL(fp), ALLOCATABLE :: OHCH4_LOSS(:,:,:)
      REAL(fp), ALLOCATABLE :: CH4_MASS(:,:,:)
      REAL(fp), ALLOCATABLE :: CH4_TROPMASS(:,:,:)
      REAL(fp), ALLOCATABLE :: CH4_EMIS(:,:,:)
      
      CONTAINS
!EOC
!------------------------------------------------------------------------------
!                  GEOS-Chem Global Chemical Transport Model                  !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: do_diag_oh
!
! !DESCRIPTION: Subroutine DO\_DIAG\_OH sums the OH and air mass (from 
!  SMVGEAR arrays) for the mean OH concentration diagnostic. 
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE DO_DIAG_OH()
!
! !USES:
!
      USE CMN_SIZE_MOD
      USE COMODE_MOD,     ONLY : AIRDENS, CSPEC, JLOP, T3, VOLUME
      USE COMODE_LOOP_MOD
      USE TRACERID_MOD,   ONLY : IDOH
! 
! !REVISION HISTORY:
!  07 Jul 2004 - R. Yantosca - Initial version
!  15 Sep 2010 - R. Yantosca - Added ProTeX headers
!  19 Dec 2014 - R. Yantosca - Use REAL*8 variables to avoid precision loss
!  19 Dec 2014 - R. Yantosca - Remove FIRST & XLOSS; they aren't used anymore
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      INTEGER  :: I,          J
      INTEGER  :: L,          JLOOP
      REAL(f8) :: AIRDENS_8,  VOLUME_8
      REAL(f8) :: XOHMASS,    XAIRMASS

      !=================================================================
      ! DO_DIAG_OH begins here!
      !=================================================================

      ! Safety valve -- avoid seg faults
      IF ( .not. DO_SAVE_OH ) RETURN

      ! Loop over boxes
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, L, JLOOP, XAIRMASS, XOHMASS, AIRDENS_8, VOLUME_8 )
!$OMP+SCHEDULE( DYNAMIC )
      DO L = 1, NPVERT
      DO J = 1, NLAT
      DO I = 1, NLONG

         ! 1-D grid box index
         JLOOP = JLOP(I,J,L)

         ! Cycle if this isn't a valid SMVGEAR gridbox
         IF ( JLOOP > 0 ) THEN
         
            ! Cast from REAL*8 to avoid underflow
            AIRDENS_8       = AIRDENS(JLOOP)
            VOLUME_8        = VOLUME(JLOOP)

            ! Sum air mass term into AIR_MASS array
            XAIRMASS        = AIRDENS_8         * VOLUME_8
            AIR_MASS(I,J,L) = AIR_MASS(I,J,L)   + XAIRMASS

            ! Sum OH mass term into OH_MASS array
            XOHMASS         = CSPEC(JLOOP,IDOH) * XAIRMASS
            OH_MASS(I,J,L)  = OH_MASS(I,J,L)    + XOHMASS

         ENDIF
      ENDDO
      ENDDO
      ENDDO
!$OMP END PARALLEL DO
         
      END SUBROUTINE DO_DIAG_OH
!EOC
!------------------------------------------------------------------------------
!                  GEOS-Chem Global Chemical Transport Model                  !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: do_diag_oh_ch4
!
! !DESCRIPTION: Subroutine DO\_DIAG\_OH\_CH4 passes the OH loss, OH mass, 
!  and air mass terms from "global\_ch4\_mod.f" to "diag\_oh\_mod.f" 
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE DO_DIAG_OH_CH4( I, J, L, XOHMASS, XAIRMASS, XLOSS,
     &                   XCH4LOSS, XCH4TROPMASS, XCH4EMIS, XCH4MASS )
!
! !USES:
!

!
! !INPUT PARAMETERS: 
!
      INTEGER,  INTENT(IN) :: I             ! Longitude index
      INTEGER,  INTENT(IN) :: J             ! Latitude index
      INTEGER,  INTENT(IN) :: L             ! Level index
      REAL(fp), INTENT(IN) :: XOHMASS       ! OH Mass  (from global_ch4_mod.f)
      REAL(fp), INTENT(IN) :: XAIRMASS      ! Air mass (from global_ch4_mod.f)
      REAL(fp), INTENT(IN) :: XLOSS         ! Loss of ch3ccl3 by OH
      REAL(fp), INTENT(IN) :: XCH4LOSS      ! Loss of ch4 by OH
      REAL(fp), INTENT(IN) :: XCH4MASS      ! CH4 Mass  (from global_ch4_mod.f)
      REAL(fp), INTENT(IN) :: XCH4TROPMASS  ! CH4 Mass  (from global_ch4_mod.f)
      REAL(fp), INTENT(IN) :: XCH4EMIS      ! CH4 emissions
! 
! !REVISION HISTORY:
!  07 Jul 2004 - R. Yantosca - Initial version
!  15 Sep 2010 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
      !=================================================================
      ! DO_DIAG_OH_CH4 begins here!
      !=================================================================

      ! Sum air mass & OH mass into arrays
      AIR_MASS(I,J,L)     = AIR_MASS(I,J,L)     + XAIRMASS
      OH_MASS(I,J,L)      = OH_MASS(I,J,L)      + XOHMASS
      OH_LOSS(I,J,L)      = OH_LOSS(I,J,L)      + XLOSS
      OHCH4_LOSS(I,J,L)   = OHCH4_LOSS(I,J,L)   + XCH4LOSS
      CH4_MASS(I,J,L)     = CH4_MASS(I,J,L)     + XCH4MASS
      CH4_TROPMASS(I,J,L) = CH4_TROPMASS(I,J,L) + XCH4TROPMASS
      CH4_EMIS(I,J,L)     = CH4_EMIS(I,J,L)     + XCH4EMIS

      END SUBROUTINE DO_DIAG_OH_CH4
!EOC
!------------------------------------------------------------------------------
!                  GEOS-Chem Global Chemical Transport Model                  !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: print_diag_oh
!
! !DESCRIPTION: Subroutine PRINT\_DIAG\_OH prints the mass-weighted OH 
!  concentration at the end of a simulation. 
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE PRINT_DIAG_OH( am_I_Root, Input_Opt, RC )
!
! !USES:
!
      USE GIGC_ErrCode_Mod
      USE GIGC_Input_Opt_Mod, ONLY : OptInput
!
! !INPUT PARAMETERS:
!
      LOGICAL,        INTENT(IN)  :: am_I_Root   ! Are we on the root CPU?
      TYPE(OptInput), INTENT(IN)  :: Input_Opt   ! Input Options object
!
! !OUTPUT PARAMETERS:
!
      INTEGER,        INTENT(OUT) :: RC          ! Success or failure?
! 
! !REVISION HISTORY: 
!  21 Oct 2003 - R. Yantosca - Initial version
!  15 Sep 2010 - R. Yantosca - Added ProTeX headers
!  25 Jun 2014 - R. Yantosca - Now accept am_I_Root, Input_Opt, RC
!  25 Jun 2014 - R. Yantosca - Now remove references to tracer_mod.F
!  08 Jan 2015 - M. Yannetti - Set variables to F8 as needed
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      REAL(f8) :: SUM_OHMASS, SUM_MASS, SUM_OHLOSS
      REAL(f8) :: SUM_OHCH4LOSS, SUM_CH4MASS
      REAL(f8) :: SUM_CH4EMIS, SUM_CH4TROPMASS
      REAL(fp) :: OHCONC, LIFETIME
      
      LOGICAL  :: LPRT
      !=================================================================
      ! PRINT_DIAG_OH begins here!
      !=================================================================

      LPRT = ( Input_Opt%LPRT .and. am_I_Root )

      ! Assume success
      RC         = GIGC_SUCCESS

      ! Return if this diagnostic is turned off
      IF ( .not. DO_SAVE_OH ) RETURN


      !IF ( LPRT ) THEN
      ! PRINT*, "### OH_MASS: ", OH_MASS
      ! FLUSH (6)
      !END IF
      ! Total Mass-weighted OH [molec OH/cm3] * [molec air]
      SUM_OHMASS = SUM( OH_MASS )

      ! Atmospheric air mass [molec air]
      SUM_MASS   = SUM( AIR_MASS ) 

      ! OH Loss from CH3CCl3 + OH [molec / box / s]
      SUM_OHLOSS = SUM( OH_LOSS )

      ! OH Loss from CH4 + OH [molec / box / s]
      SUM_OHCH4LOSS = SUM( OHCH4_LOSS )

      ! Atmospheric mass of CH4
      SUM_CH4MASS = SUM( CH4_MASS )

      ! Atmospheric mass of tropospheric CH4
      SUM_CH4TROPMASS = SUM( CH4_TROPMASS )

      ! Atmospheric ch4 emissions
      SUM_CH4EMIS = SUM( CH4_EMIS )
         
      ! Avoid divide-by-zero errors 
      IF ( SUM_MASS > 0e+0_fp ) THEN 
            
         ! Divide OH by [molec air] and report as [1e5 molec/cm3]
         OHCONC = ( SUM_OHMASS / SUM_MASS ) / 1e+5_fp
         
         ! Write value to log file
         IF ( am_I_Root ) THEN
            WRITE( 6, '(/,a)' ) REPEAT( '=', 79 ) 
            WRITE( 6, *       ) 'ND23: Mass-Weighted OH Concentration'
            WRITE( 6, *       ) 'Mean OH = ', OHCONC, ' [1e5 molec/cm3]' 
            WRITE( 6, '(  a)' ) REPEAT( '=', 79 ) 
         ENDIF

         ! Avoid divide-by-zero errors
         IF ( Input_Opt%ITS_A_CH4_SIM .and. am_I_Root ) THEN
            IF ( SUM_OHLOSS > 0 ) THEN

               ! Mass weighted lifetimes printed below
               WRITE( 6, * ) 'All lifetimes printed below ' //
     &                       'are mass-weighted'
               WRITE( 6, '(  a)' ) REPEAT( '-', 79 )

               ! Calculate CH3CCl3 Lifetime [years]
               LIFETIME = ( SUM_MASS / SUM_OHLOSS ) / 
     &                    ( 3600e+0_fp*365e+0_fp*24e+0_fp )

               ! Write value to log file
               WRITE( 6, *       ) 'Methyl Chloroform (CH3CCl3)'
               WRITE( 6, *       ) 'Tropospheric Lifetime     = ', 
     &                                 LIFETIME, ' [years]'
               WRITE( 6, '(  a)' ) REPEAT( '=', 79 )

               ! Calculate CH4 lifetime w/r/t OH loss [years]
               LIFETIME = ( SUM_MASS / SUM_OHCH4LOSS ) / 
     &                    ( 3600e+0_fp*365e+0_fp*24e+0_fp )
               ! Write value to log file
               WRITE( 6, *       ) 'Methane (CH4)'
               WRITE( 6, *       ) 'Tropospheric Lifetime w/r/t OH  = ', 
     &                                 LIFETIME, ' [years]'
               WRITE( 6, '(  a)' ) REPEAT( '=', 79 )

               ! Calculate CH4 lifetime  [years]
               LIFETIME = ( SUM_CH4TROPMASS / SUM_CH4EMIS ) / 
     &                    ( 3600e+0_fp*365e+0_fp*24e+0_fp )
               ! Write value to log file
               WRITE( 6, *       ) 'Methane (CH4)'
               WRITE( 6, *       ) 'Tropospheric Lifetime (total)  = ', 
     &                                 LIFETIME, ' [years]'
               WRITE( 6, '(  a)' ) REPEAT( '=', 79 )

               ! Calculate CH4 lifetime  [years]
               LIFETIME = ( SUM_CH4MASS / SUM_CH4EMIS ) / 
     &                    ( 3600e+0_fp*365e+0_fp*24e+0_fp )
               ! Write value to log file
               WRITE( 6, *       ) 'Methane (CH4)'
               WRITE( 6, *       ) 'Global Lifetime (total)  = ', 
     &                                 LIFETIME, ' [years]'
               WRITE( 6, '(  a)' ) REPEAT( '=', 79 )

            ELSE

               WRITE( 6, *       ) 'Could not compute CH3CCl3 lifetime!'
               WRITE( 6, *       ) 'SUM_OHLOSS = 0!'
               WRITE( 6, '(  a)' ) REPEAT( '=', 79 )

            ENDIF
         ENDIF
      ELSE

         ! Write error msg if SUM_MASS is zero
         IF ( am_I_Root ) THEN
            WRITE( 6, '(/,a)' ) REPEAT( '=', 79 ) 
            WRITE( 6, '(  a)' ) 'Could not print mass-weighted OH!'
            WRITE( 6, '(  a)' ) 'Atmospheric air mass is zero!'
            WRITE( 6, '(  a)' ) REPEAT( '=', 79 ) 
         ENDIF
            
      ENDIF

      END SUBROUTINE PRINT_DIAG_OH
!EOC
!------------------------------------------------------------------------------
!                  GEOS-Chem Global Chemical Transport Model                  !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: init_diag_oh
!
! !DESCRIPTION: Subroutine INIT\_DIAG\_OH initializes all module arrays. 
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE INIT_DIAG_OH( am_I_Root, Input_Opt, RC )
!
! !USES:
!
      USE CMN_SIZE_MOD
      USE GIGC_ErrCode_Mod
      USE GIGC_Input_Opt_Mod, ONLY : OptInput
      USE ERROR_MOD,          ONLY : ALLOC_ERR
!
! !INPUT VARIABLES:
!
      LOGICAL,        INTENT(IN)  :: am_I_Root
      TYPE(OptInput), INTENT(IN)  :: Input_Opt   ! Input Options object
!
! !OUTPUT PARAMETERS:
!
      INTEGER,        INTENT(OUT) :: RC          ! Success or failure?
! 
! !REVISION HISTORY: 
!  07 Jul 2004 - R. Yantosca - Initial version
!  (1 ) Remove references to CO-OH simulation and to CMN_DIAG (bmy, 6/24/05)
!  15 Sep 2010 - R. Yantosca - Added ProTeX headers
!  23 Jun 2014 - R. Yantosca - Removed reference to logical_mod.F
!  23 Jun 2014 - R. Yantosca - Removed reference to tracer_mod.F
!EOP
!------------------------------------------------------------------------------
!BOC
!
! !LOCAL VARIABLES:
!
      INTEGER :: AS, LMAX

      !=================================================================
      ! INIT_DIAG_OH begins here!
      !=================================================================

      ! Initialize
      DO_SAVE_OH = .FALSE.

      ! Return if we are not doing chemistry
      IF ( .not. Input_Opt%LCHEM ) RETURN

      ! Set vertical levels and decide whether to print CH3CCl3
      ! lifetime or just mean mass-weighted OH concentration
      IF ( Input_Opt%ITS_A_FULLCHEM_SIM ) THEN

         ! Fullchem: chemistry grid only
         LMAX       = LLCHEM
         DO_SAVE_OH = .TRUE.

      ELSE IF ( Input_Opt%ITS_A_CH4_SIM ) THEN

         ! CH4: all levels
         LMAX       = LLPAR
         DO_SAVE_OH = .TRUE.

      ENDIF

      ! Echo info
      IF ( am_I_Root ) THEN 
         WRITE( 6, 100 ) DO_SAVE_OH
 100     FORMAT( /, 'Turn on Mean OH diagnostic (ND23)? :', L5 )
      ENDIF

      ! Return if we aren't saving mean OH
      IF ( .not. DO_SAVE_OH ) RETURN

      !=================================================================
      ! Allocate arrays
      !=================================================================

      ! Air mass array
      ALLOCATE( AIR_MASS( IIPAR, JJPAR, LMAX ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'AIR_MASS' )
      AIR_MASS = 0e+0_fp

      ! OH mass array
      ALLOCATE( OH_MASS( IIPAR, JJPAR, LMAX ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'OH_MASS' )
      OH_MASS = 0e+0_fp

      ALLOCATE( OH_LOSS( IIPAR, JJPAR, LMAX ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'OH_LOSS' )
      OH_LOSS = 0e+0_fp

      ALLOCATE( OHCH4_LOSS( IIPAR, JJPAR, LMAX ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'OHCH4_LOSS' )
      OHCH4_LOSS = 0e+0_fp

      ALLOCATE( CH4_MASS( IIPAR, JJPAR, LMAX ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'CH4_MASS' )
      CH4_MASS = 0e+0_fp

      ALLOCATE( CH4_TROPMASS( IIPAR, JJPAR, LMAX ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'CH4_TROPMASS' )
      CH4_TROPMASS = 0e+0_fp

      ALLOCATE( CH4_EMIS( IIPAR, JJPAR, LMAX ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'CH4_EMIS' )
      CH4_EMIS = 0e+0_fp

      END SUBROUTINE INIT_DIAG_OH
!EOC
!------------------------------------------------------------------------------
!                  GEOS-Chem Global Chemical Transport Model                  !
!------------------------------------------------------------------------------
!BOP
!
! !IROUTINE: cleanup_diag_oh
!
! !DESCRIPTION: Subroutine CLEANUP\_DIAG\_OH deallocates all module arrays.
!\\
!\\
! !INTERFACE:
!
      SUBROUTINE CLEANUP_DIAG_OH
! 
! !REVISION HISTORY: 
!  07 Jul 2004 - R. Yantosca - Initial version
!  15 Sep 2010 - R. Yantosca - Added ProTeX headers
!EOP
!------------------------------------------------------------------------------
!BOC
      !=================================================================
      ! CLEANUP_DIAG_OH begins here!
      !=================================================================
      IF ( ALLOCATED( OH_MASS  ) ) DEALLOCATE( OH_MASS  )
      IF ( ALLOCATED( AIR_MASS ) ) DEALLOCATE( AIR_MASS )
      IF ( ALLOCATED( OH_LOSS  ) ) DEALLOCATE( OH_LOSS  )
      IF ( ALLOCATED( OHCH4_LOSS  ) ) DEALLOCATE( OHCH4_LOSS  )
      IF ( ALLOCATED( CH4_MASS  ) ) DEALLOCATE( CH4_MASS  )
      IF ( ALLOCATED( CH4_TROPMASS  ) ) DEALLOCATE( CH4_TROPMASS  )
      IF ( ALLOCATED( CH4_EMIS  ) ) DEALLOCATE( CH4_EMIS  )

      END SUBROUTINE CLEANUP_DIAG_OH
!EOC
      END MODULE DIAG_OH_MOD
