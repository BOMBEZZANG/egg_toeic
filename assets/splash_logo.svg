<svg viewBox="0 0 200 200" width="1024" height="1024" xmlns="http://www.w3.org/2000/svg">
  <!-- 배경 원 (앱 아이콘 형태) -->
  <rect width="200" height="200" rx="40" fill="url(#bgGradient)"/>
  
  <!-- 그라디언트 정의 -->
  <defs>
    <!-- 배경 그라디언트 -->
    <linearGradient id="bgGradient" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" style="stop-color:#4A90E2;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#357ABD;stop-opacity:1" />
    </linearGradient>
    
    <!-- 타조알 그라디언트 -->
    <radialGradient id="eggGradient" cx="45%" cy="40%">
      <stop offset="0%" style="stop-color:#FFF8E7;stop-opacity:1" />
      <stop offset="70%" style="stop-color:#F5E6D3;stop-opacity:1" />
      <stop offset="100%" style="stop-color:#E8D4B8;stop-opacity:1" />
    </radialGradient>
    
    <!-- 타조알 반점 패턴 -->
    <pattern id="speckles" x="0" y="0" width="40" height="40" patternUnits="userSpaceOnUse">
      <circle cx="5" cy="5" r="2" fill="#D4B896" opacity="0.3"/>
      <circle cx="15" cy="12" r="1.5" fill="#C8A882" opacity="0.25"/>
      <circle cx="25" cy="8" r="2.5" fill="#D4B896" opacity="0.35"/>
      <circle cx="35" cy="15" r="1.8" fill="#C8A882" opacity="0.3"/>
      <circle cx="8" cy="25" r="2" fill="#D4B896" opacity="0.28"/>
      <circle cx="20" cy="30" r="2.2" fill="#C8A882" opacity="0.32"/>
      <circle cx="32" cy="28" r="1.6" fill="#D4B896" opacity="0.26"/>
      <circle cx="12" cy="35" r="1.9" fill="#C8A882" opacity="0.29"/>
    </pattern>
    
    <!-- 하이라이트 -->
    <radialGradient id="highlight" cx="35%" cy="30%">
      <stop offset="0%" style="stop-color:#FFFFFF;stop-opacity:0.7" />
      <stop offset="50%" style="stop-color:#FFFFFF;stop-opacity:0.3" />
      <stop offset="100%" style="stop-color:#FFFFFF;stop-opacity:0" />
    </radialGradient>
    
    <!-- 그림자 필터 -->
    <filter id="shadow" x="-50%" y="-50%" width="200%" height="200%">
      <feGaussianBlur in="SourceAlpha" stdDeviation="3"/>
      <feOffset dx="0" dy="4" result="offsetblur"/>
      <feComponentTransfer>
        <feFuncA type="linear" slope="0.3"/>
      </feComponentTransfer>
      <feMerge>
        <feMergeNode/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>
  
  <!-- 타조알 메인 형태 -->
  <ellipse cx="100" cy="105" rx="55" ry="65" fill="url(#eggGradient)" filter="url(#shadow)"/>
  
  <!-- 타조알 반점 오버레이 -->
  <ellipse cx="100" cy="105" rx="55" ry="65" fill="url(#speckles)" opacity="0.6"/>
  
  <!-- 하이라이트 효과 -->
  <ellipse cx="85" cy="85" rx="25" ry="30" fill="url(#highlight)"/>
  

  
  <!-- 별 장식 (학습 성취감 표현) -->
  <g transform="translate(65, 65)">
    <path d="M0,-8 L2,-2 L8,-1 L3,3 L2,9 L0,4 L-2,9 L-3,3 L-8,-1 L-2,-2 Z" fill="#FFD700" opacity="0.9"/>
  </g>
  
  <!-- 작은 별들 -->
  <circle cx="130" cy="75" r="2" fill="#FFD700" opacity="0.7"/>
  <circle cx="75" cy="140" r="1.5" fill="#FFD700" opacity="0.6"/>
  <circle cx="125" cy="105" r="1.5" fill="#FFD700" opacity="0.5"/>
</svg>