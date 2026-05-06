import { Component } from '@angular/core';
import { NavbarComponent } from './components/navbar/navbar.component';
import { HeroComponent } from './components/hero/hero.component';
import { AboutComponent } from './components/about/about.component';
import { FeaturesComponent } from './components/features/features.component';
import { TeamComponent } from './components/team/team.component';
import { DownloadComponent } from './components/download/download.component';

@Component({
  selector: 'app-root',
  standalone: true,
  imports: [
    NavbarComponent,
    HeroComponent,
    AboutComponent,
    FeaturesComponent,
    TeamComponent,
    DownloadComponent
  ],
  templateUrl: './app.component.html',
})
export class AppComponent {}
