   !        Generated by TAPENADE     (INRIA, Tropics team)
   !  Tapenade 3.10 (r5363) -  9 Sep 2014 09:53
   !
   !
   !      ******************************************************************
   !      *                                                                *
   !      * File:          flowVarRefState.f90                             *
   !      * Author:        Edwin van der Weide , Seonghyeon Hahn           *
   !      * Starting date: 01-03-2003                                      *
   !      * Last modified: 08-16-2005                                      *
   !      *                                                                *
   !      ******************************************************************
   !
   MODULE FLOWVARREFSTATE_B
   !
   !      ******************************************************************
   !      *                                                                *
   !      * Module that contains information about the reference state as  *
   !      * well as the nondimensional free stream state.                  *
   !      *                                                                *
   !      ******************************************************************
   !
   USE CONSTANTS
   IMPLICIT NONE
   SAVE 
   ! nw:       Total number of independent variables including the
   !           turbulent variables.
   ! nwf:      Number of flow variables. For perfect gas computations
   !           this is 5.
   ! nwt:      Number of turbulent variables, nwt = nw - nwf
   ! nt1, nt2: Initial and final indices for turbulence variables
   INTEGER(kind=inttype) :: nw, nwf, nwt, nt1, nt2
   ! pRef:     Reference pressure (in Pa) used to nondimensionalize
   !           the flow equations.
   ! rhoRef:   Reference density (in kg/m^3) used to
   !           nondimensionalize the flow equations.
   ! TRef:     Reference temperature (in K) used to nondimensionalize
   !           the flow equations.
   ! muRef:    Scale for the viscosity, 
   !           muRef = rhoRef*sqrt(pRef/rhoRef); there is also a
   !           reference length in the nondimensionalization of mu,
   !           but this is 1.0, because all the coordinates are 
   !           converted to meters.
   ! timeRef:  time scale; needed for a correct 
   !           nondimensionalization of unsteady problems.
   !           timeRef = sqrt(rhoRef/pRef); for the reference
   !           length, see the comments for muRef.
   REAL(kind=realtype) :: pref, rhoref, tref
   REAL(kind=realtype) :: prefb, rhorefb, trefb
   REAL(kind=realtype) :: muref, timeref
   REAL(kind=realtype) :: murefb, timerefb
   ! LRef:          Conversion factor of the length unit of the
   !                grid to meter. e.g. if the grid is in mm.,
   !                LRef = 1.e-3.
   ! LRefSpecified: Whether or not a conversion factor is specified
   !                in the input file.
   REAL(kind=realtype) :: lref
   LOGICAL :: lrefspecified
   ! pInfDim:   Free stream pressure in Pa.
   ! rhoInfDim: Free stream density in kg/m^3.
   ! muDim:     Free stream molecular viscosity in kg/(m s)
   REAL(kind=realtype) :: pinfdim, rhoinfdim, mudim
   REAL(kind=realtype) :: pinfdimb, rhoinfdimb, mudimb
   !AD derivative values
   ! wInf(nw): Nondimensional free stream state vector.
   !           Variables stored are rho, u, v, w and rhoE.
   ! pInf:     Nondimensional free stream pressure.
   ! pInfCorr: Nondimensional free stream pressure, corrected for
   !           a possible presence of 2/3 rhok.
   ! rhoInf:   Nondimensional free stream density.
   ! uInf:     Nondimensional free stream velocity
   ! muInf:    Nondimensional free stream viscosity.
   ! RGas:     Nondimensional gas constant.
   ! gammaInf: Free stream specific heat ratio.
   REAL(kind=realtype) :: rhoinf, uinf, pinf, pinfcorr
   REAL(kind=realtype) :: rhoinfb, uinfb, pinfb, pinfcorrb
   REAL(kind=realtype) :: rgas, muinf, gammainf
   REAL(kind=realtype) :: rgasb, muinfb, gammainfb
   REAL(kind=realtype), DIMENSION(10) :: winf
   REAL(kind=realtype), DIMENSION(10) :: winfb
   ! viscous:   whether or not this is a viscous computation.
   ! kPresent:  whether or not a turbulent kinetic energy is present
   !            in the turbulence model.
   ! eddyModel: whether or not the turbulence model is an eddy
   !            viscosity model.
   LOGICAL :: kpresent, eddymodel, viscous
   END MODULE FLOWVARREFSTATE_B
